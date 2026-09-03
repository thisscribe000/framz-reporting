import { Router, Response } from 'express';
import { query } from '../db';
import { authenticateToken, AuthRequest } from '../middleware/auth';

const router = Router();

function safeNum(val: any): number {
  if (val === null || val === undefined) return 0;
  const parsed = parseFloat(String(val));
  return isNaN(parsed) ? 0 : parsed;
}

// GET Dashboard Growth Analytics
router.get('/dashboard', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const period = (req.query.period as string) || 'monthly';
    const isFinanceAuthorized = ['ADMIN', 'PASTOR', 'FINANCE'].includes(req.user?.role || '');

    // 1. Membership Statistics
    const memberCounts = await query(`
      SELECT 
        COUNT(*) as total_members,
        SUM(CASE WHEN status = 'ACTIVE' THEN 1 ELSE 0 END) as active_members,
        SUM(CASE WHEN status = 'NEW_CONVERT' THEN 1 ELSE 0 END) as new_converts,
        SUM(CASE WHEN status = 'FIRST_TIMER' THEN 1 ELSE 0 END) as first_timers,
        SUM(CASE WHEN status = 'INACTIVE' THEN 1 ELSE 0 END) as inactive_members
      FROM members
    `);

    // 2. Date ranges
    const now = new Date();
    let currentStartDate: Date;
    let prevStartDate: Date;
    let prevEndDate: Date;

    if (period === 'weekly') {
      currentStartDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      prevEndDate = new Date(currentStartDate.getTime() - 1);
      prevStartDate = new Date(prevEndDate.getTime() - 7 * 24 * 60 * 60 * 1000);
    } else if (period === 'quarterly') {
      currentStartDate = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
      prevEndDate = new Date(currentStartDate.getTime() - 1);
      prevStartDate = new Date(prevEndDate.getTime() - 90 * 24 * 60 * 60 * 1000);
    } else if (period === 'yearly') {
      currentStartDate = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
      prevEndDate = new Date(currentStartDate.getTime() - 1);
      prevStartDate = new Date(prevEndDate.getTime() - 365 * 24 * 60 * 60 * 1000);
    } else {
      currentStartDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      prevEndDate = new Date(currentStartDate.getTime() - 1);
      prevStartDate = new Date(prevEndDate.getTime() - 30 * 24 * 60 * 60 * 1000);
    }

    const currStartStr = currentStartDate.toISOString().split('T')[0];
    const prevStartStr = prevStartDate.toISOString().split('T')[0];
    const prevEndStr = prevEndDate.toISOString().split('T')[0];

    // 3. Attendance Metrics
    const sundayServiceTypes = await query("SELECT id FROM service_types WHERE category = 'SUNDAY'");
    const sundayTypeId = sundayServiceTypes[0]?.id || 1;

    const currentSundayAtt = await query(
      `SELECT AVG(headcount_male + headcount_female + headcount_children) as avg_attendance,
              COUNT(*) as event_count
       FROM attendances 
       WHERE service_type_id = ? AND event_date >= ?`,
      [sundayTypeId, currStartStr]
    );

    const prevSundayAtt = await query(
      `SELECT AVG(headcount_male + headcount_female + headcount_children) as avg_attendance
       FROM attendances 
       WHERE service_type_id = ? AND event_date >= ? AND event_date <= ?`,
      [sundayTypeId, prevStartStr, prevEndStr]
    );

    const currAvgSunday = Math.round(safeNum(currentSundayAtt[0]?.avg_attendance));
    const prevAvgSunday = Math.round(safeNum(prevSundayAtt[0]?.avg_attendance));
    const sundayGrowthPct = prevAvgSunday > 0 ? (((currAvgSunday - prevAvgSunday) / prevAvgSunday) * 100).toFixed(1) : '0';

    // 3b. Midweek Attendance Metrics
    const midweekServiceTypes = await query("SELECT id FROM service_types WHERE category = 'MIDWEEK'");
    const midweekTypeId = midweekServiceTypes[0]?.id || 2;

    const currentMidweekAtt = await query(
      `SELECT AVG(headcount_male + headcount_female + headcount_children) as avg_attendance
       FROM attendances 
       WHERE service_type_id = ? AND event_date >= ?`,
      [midweekTypeId, currStartStr]
    );

    const prevMidweekAtt = await query(
      `SELECT AVG(headcount_male + headcount_female + headcount_children) as avg_attendance
       FROM attendances 
       WHERE service_type_id = ? AND event_date >= ? AND event_date <= ?`,
      [midweekTypeId, prevStartStr, prevEndStr]
    );

    const currAvgMidweek = Math.round(safeNum(currentMidweekAtt[0]?.avg_attendance));
    const prevAvgMidweek = Math.round(safeNum(prevMidweekAtt[0]?.avg_attendance));
    const midweekGrowthPct = prevAvgMidweek > 0 ? (((currAvgMidweek - prevAvgMidweek) / prevAvgMidweek) * 100).toFixed(1) : '0';

    // 3c. Cell Group Breakdown
    const cellBreakdown = await query(`
      SELECT c.id, c.name, c.leader_name, COUNT(m.id) as member_count
      FROM cell_groups c
      LEFT JOIN members m ON m.cell_id = c.id
      GROUP BY c.id, c.name, c.leader_name
      ORDER BY member_count DESC
    `);

    // 3d. Recent First Timers & New Converts Pipeline
    const firstTimersList = await query(`
      SELECT m.id, m.first_name, m.last_name, m.phone, m.status, m.follow_up_stage, m.date_joined, c.name as cell_name
      FROM members m
      LEFT JOIN cell_groups c ON m.cell_id = c.id
      WHERE m.status IN ('FIRST_TIMER', 'NEW_CONVERT')
      ORDER BY m.date_joined DESC, m.id DESC
      LIMIT 10
    `);

    // 4. Attendance Trends
    const rawTrends = await query(`
      SELECT 
        a.event_date,
        st.category,
        (a.headcount_male + a.headcount_female + a.headcount_children) as total_attendance,
        a.headcount_male,
        a.headcount_female,
        a.headcount_children
      FROM attendances a
      JOIN service_types st ON a.service_type_id = st.id
      ORDER BY a.event_date DESC
      LIMIT 20
    `);

    const attendanceTrends = rawTrends.map((t: any) => ({
      event_date: t.event_date || '',
      category: t.category || '',
      total_attendance: safeNum(t.total_attendance || (safeNum(t.headcount_male) + safeNum(t.headcount_female) + safeNum(t.headcount_children))),
      headcount_male: safeNum(t.headcount_male),
      headcount_female: safeNum(t.headcount_female),
      headcount_children: safeNum(t.headcount_children)
    }));

    // 5. Financial Growth Metrics
    let financialSummary = null;
    if (isFinanceAuthorized) {
      const currentOfferings = await query(
        `SELECT SUM(amount) as total_amount FROM offerings WHERE event_date >= ?`,
        [currStartStr]
      );
      const prevOfferings = await query(
        `SELECT SUM(amount) as total_amount FROM offerings WHERE event_date >= ? AND event_date <= ?`,
        [prevStartStr, prevEndStr]
      );

      const currTotalFin = safeNum(currentOfferings[0]?.total_amount);
      const prevTotalFin = safeNum(prevOfferings[0]?.total_amount);
      const finGrowthPct = prevTotalFin > 0 ? (((currTotalFin - prevTotalFin) / prevTotalFin) * 100).toFixed(1) : '0';

      const rawOfferings = await query(`
        SELECT offering_type, SUM(amount) as total_amount
        FROM offerings
        WHERE event_date >= ?
        GROUP BY offering_type
        ORDER BY total_amount DESC
      `, [currStartStr]);

      const offeringBreakdown = rawOfferings.map((o: any) => ({
        offering_type: o.offering_type || 'OTHER',
        total_amount: safeNum(o.total_amount)
      }));

      financialSummary = {
        currentTotal: currTotalFin,
        previousTotal: prevTotalFin,
        growthPercentage: parseFloat(finGrowthPct),
        offeringBreakdown
      };
    }

    res.json({
      period,
      membership: {
        total: Math.round(safeNum(memberCounts[0]?.total_members)),
        active: Math.round(safeNum(memberCounts[0]?.active_members)),
        newConverts: Math.round(safeNum(memberCounts[0]?.new_converts)),
        firstTimers: Math.round(safeNum(memberCounts[0]?.first_timers)),
        inactive: Math.round(safeNum(memberCounts[0]?.inactive_members)),
      },
      sundayAttendance: {
        currentAverage: currAvgSunday,
        previousAverage: prevAvgSunday,
        growthPercentage: parseFloat(sundayGrowthPct)
      },
      midweekAttendance: {
        currentAverage: currAvgMidweek,
        previousAverage: prevAvgMidweek,
        growthPercentage: parseFloat(midweekGrowthPct)
      },
      cellBreakdown: cellBreakdown.map((c: any) => ({
        id: c.id,
        name: c.name,
        leaderName: c.leader_name,
        memberCount: Math.round(safeNum(c.member_count))
      })),
      firstTimersList: firstTimersList.map((m: any) => ({
        id: m.id,
        fullName: `${m.first_name} ${m.last_name}`,
        phone: m.phone || 'N/A',
        status: m.status,
        followUpStage: m.follow_up_stage || 'PENDING',
        dateJoined: m.date_joined,
        cellName: m.cell_name || 'Unassigned'
      })),
      attendanceTrends: attendanceTrends.reverse(),
      financials: financialSummary
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
