import { Router, Response } from 'express';
import { query } from '../db';
import { authenticateToken, AuthRequest, authorizeRoles } from '../middleware/auth';

const router = Router();

// GET financial logs (Restricted to ADMIN, PASTOR, FINANCE)
router.get('/', authenticateToken, authorizeRoles('ADMIN', 'PASTOR', 'FINANCE'), async (req: AuthRequest, res: Response) => {
  try {
    const { offering_type, start_date, end_date, limit } = req.query;
    let sql = `
      SELECT o.*, st.name as service_name, u.full_name as recorder_name
      FROM offerings o
      LEFT JOIN service_types st ON o.service_type_id = st.id
      LEFT JOIN users u ON o.recorded_by = u.id
      WHERE 1=1
    `;
    const params: any[] = [];

    if (offering_type) {
      sql += ' AND o.offering_type = ?';
      params.push(offering_type);
    }
    if (start_date) {
      sql += ' AND o.event_date >= ?';
      params.push(start_date);
    }
    if (end_date) {
      sql += ' AND o.event_date <= ?';
      params.push(end_date);
    }

    sql += ' ORDER BY o.event_date DESC, o.id DESC';
    if (limit) {
      sql += ` LIMIT ${parseInt(String(limit), 10)}`;
    }

    const offerings = await query(sql, params);
    res.json(offerings);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// POST Record financial contribution / offering
router.post('/', authenticateToken, authorizeRoles('ADMIN', 'PASTOR', 'FINANCE'), async (req: AuthRequest, res: Response) => {
  try {
    const { service_type_id, event_date, offering_type, amount, currency, notes } = req.body;
    if (!service_type_id || !event_date || !offering_type || amount === undefined) {
      return res.status(400).json({ error: 'Service type, date, offering type, and amount are required' });
    }

    const result = await query(
      `INSERT INTO offerings (service_type_id, event_date, offering_type, amount, currency, branch_id, recorded_by, notes)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [service_type_id, event_date, offering_type, parseFloat(amount), currency || 'NGN', req.user?.branch_id || null, req.user?.id, notes || null]
    );

    res.status(201).json({ message: 'Offering recorded successfully', id: result[0]?.id });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
