import { Router, Response } from 'express';
import { query } from '../db';
import { authenticateToken, AuthRequest } from '../middleware/auth';

const router = Router();

// GET all members with filters
router.get('/', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const { status, cell_id, search } = req.query;
    let sql = `
      SELECT m.*, c.name as cell_name, b.name as branch_name 
      FROM members m 
      LEFT JOIN cell_groups c ON m.cell_id = c.id
      LEFT JOIN branches b ON m.branch_id = b.id
      WHERE 1=1
    `;
    const params: any[] = [];

    if (status) {
      sql += ' AND m.status = ?';
      params.push(status);
    }
    if (cell_id) {
      sql += ' AND m.cell_id = ?';
      params.push(cell_id);
    }
    if (search) {
      sql += ' AND (LOWER(m.first_name) LIKE ? OR LOWER(m.last_name) LIKE ? OR m.phone LIKE ?)';
      const term = `%${String(search).toLowerCase()}%`;
      params.push(term, term, term);
    }

    sql += ' ORDER BY m.created_at DESC';
    const members = await query(sql, params);
    res.json(members);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// CREATE new member
router.post('/', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const { first_name, last_name, gender, phone, email, status, date_joined, cell_id, branch_id } = req.body;
    if (!first_name || !last_name) {
      return res.status(400).json({ error: 'First name and last name are required' });
    }

    const memberStatus = status || 'ACTIVE';
    const joinedDate = date_joined || new Date().toISOString().split('T')[0];

    const result = await query(
      `INSERT INTO members (first_name, last_name, gender, phone, email, status, date_joined, cell_id, branch_id)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [first_name, last_name, gender || null, phone || null, email || null, memberStatus, joinedDate, cell_id || null, branch_id || req.user?.branch_id || null]
    );

    res.status(201).json({ message: 'Member added successfully', id: result[0]?.id });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// UPDATE member
router.put('/:id', authenticateToken, async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { first_name, last_name, gender, phone, email, status, cell_id, branch_id } = req.body;

    await query(
      `UPDATE members 
       SET first_name = ?, last_name = ?, gender = ?, phone = ?, email = ?, status = ?, cell_id = ?, branch_id = ?
       WHERE id = ?`,
      [first_name, last_name, gender, phone, email, status, cell_id || null, branch_id || null, id]
    );

    res.json({ message: 'Member updated successfully' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
