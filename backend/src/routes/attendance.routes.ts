import { Router, Response } from 'express';
import { query } from '../db';
import { authenticateToken, AuthRequest, authorizeRoles } from '../middleware/auth';

const router = Router();

// GET list of attendance logs
router.get('/', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const { service_type_id, start_date, end_date, limit } = req.query;
    let sql = `
      SELECT a.*, 
             (COALESCE(a.headcount_male, 0) + COALESCE(a.headcount_female, 0) + COALESCE(a.headcount_children, 0)) as total_headcount,
             st.name as service_name, st.category as service_category, u.full_name as recorder_name
      FROM attendances a
      LEFT JOIN service_types st ON a.service_type_id = st.id
      LEFT JOIN users u ON a.recorded_by = u.id
      WHERE 1=1
    `;
    const params: any[] = [];

    if (service_type_id) {
      sql += ' AND a.service_type_id = ?';
      params.push(service_type_id);
    }
    if (start_date) {
      sql += ' AND a.event_date >= ?';
      params.push(start_date);
    }
    if (end_date) {
      sql += ' AND a.event_date <= ?';
      params.push(end_date);
    }

    sql += ' ORDER BY a.event_date DESC, a.id DESC';
    if (limit) {
      sql += ` LIMIT ${parseInt(String(limit), 10)}`;
    }

    const records = await query(sql, params);
    res.json(records);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// GET Service Types
router.get('/service-types', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const types = await query('SELECT * FROM service_types ORDER BY id ASC');
    res.json(types);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// POST Record new attendance
router.post('/', authenticateToken, authorizeRoles('ADMIN', 'PASTOR', 'ATTENDANCE', 'CELL_LEADER'), async (req: AuthRequest, res: Response) => {
  try {
    const { service_type_id, event_date, headcount_male, headcount_female, headcount_children, cell_id, branch_id, notes } = req.body;
    if (!service_type_id || !event_date) {
      return res.status(400).json({ error: 'Service type and event date are required' });
    }

    const male = parseInt(headcount_male || '0', 10);
    const female = parseInt(headcount_female || '0', 10);
    const children = parseInt(headcount_children || '0', 10);

    const result = await query(
      `INSERT INTO attendances (service_type_id, event_date, headcount_male, headcount_female, headcount_children, cell_id, branch_id, recorded_by, notes)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [service_type_id, event_date, male, female, children, cell_id || null, branch_id || req.user?.branch_id || null, req.user?.id, notes || null]
    );

    res.status(201).json({ message: 'Attendance recorded successfully', id: result[0]?.id });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
