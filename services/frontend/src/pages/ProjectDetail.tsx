import { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { apiGet, apiPost, apiPut } from '@/api/client';
import { Project, Task, User, TaskStatus, TaskPriority } from '@wander/shared';
import { Modal } from '@/components/Modal';
import { ModalHeader } from '@/components/ModalHeader';
import { ModalBody } from '@/components/ModalBody';
import { ModalFooter } from '@/components/ModalFooter';

export function ProjectDetail() {
  const { id } = useParams<{ id: string }>();
  const [loading, setLoading] = useState(true);
  const [project, setProject] = useState<Project | null>(null);
  const [tasks, setTasks] = useState<Task[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingTask, setEditingTask] = useState<Task | null>(null);
  const [formData, setFormData] = useState({ 
    title: '', 
    description: '', 
    assigned_to: '', 
    status: 'todo', 
    priority: 'medium' 
  });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchData();
  }, [id]);

  const fetchData = () => {
    Promise.all([
      apiGet<Project>(`/api/projects/${id}`),
      apiGet<Task[]>(`/api/projects/${id}/tasks`),
      apiGet<User[]>('/api/users')
    ])
      .then(([projectData, tasksData, usersData]) => {
        setProject(projectData);
        setTasks(tasksData);
        setUsers(usersData);
      })
      .catch(err => console.error('Failed to fetch data:', err))
      .finally(() => setLoading(false));
  };

  const handleOpenModal = (task?: Task) => {
    if (task) {
      setEditingTask(task);
      setFormData({
        title: task.title,
        description: task.description || '',
        assigned_to: task.assigned_to?.toString() || '',
        status: task.status,
        priority: task.priority
      });
    } else {
      setEditingTask(null);
      setFormData({ title: '', description: '', assigned_to: '', status: 'todo', priority: 'medium' });
    }
    setError('');
    setIsModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError('');
    try {
      const payload = {
        ...formData,
        project_id: parseInt(id!),
        assigned_to: formData.assigned_to ? parseInt(formData.assigned_to) : null
      };
      
      if (editingTask) {
        await apiPut(`/api/tasks/${editingTask.id}`, payload);
      } else {
        await apiPost('/api/tasks', payload);
      }
      
      setIsModalOpen(false);
      fetchData();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save task');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) return <div className="text-center p-8">Loading...</div>;
  if (!project) return <div className="text-center p-8 text-red-500">Project not found</div>;

  return (
    <div className="container mx-auto p-4">
      <div className="bg-white p-6 rounded shadow mb-6">
        <h1 className="text-2xl font-bold mb-2">{project.name}</h1>
        <p className="text-gray-600 mb-2">{project.description}</p>
        <span className={`text-xs px-2 py-1 rounded ${
          project.status === 'active' ? 'bg-green-100 text-green-800' :
          project.status === 'planning' ? 'bg-yellow-100 text-yellow-800' :
          'bg-gray-100 text-gray-800'
        }`}>
          {project.status}
        </span>
      </div>

      <div className="flex justify-between items-center mb-4">
        <h2 className="text-xl font-semibold">Tasks</h2>
        <button
          onClick={() => handleOpenModal()}
          className="bg-primary text-white px-4 py-2 rounded hover:bg-blue-600"
        >
          New Task
        </button>
      </div>

      {tasks.length === 0 ? (
        <div className="text-center p-8 text-gray-500">
          No tasks in this project.
        </div>
      ) : (
        <div className="space-y-3">
          {tasks.map(task => {
            const assignedUser = users.find(u => u.id === task.assigned_to);
            return (
              <div 
                key={task.id} 
                className="bg-white p-4 rounded shadow hover:shadow-md cursor-pointer"
                onClick={() => handleOpenModal(task)}
              >
                <div className="flex justify-between items-start mb-2">
                  <h3 className="font-semibold">{task.title}</h3>
                  <div className="flex gap-2">
                    <span className={`text-xs px-2 py-1 rounded ${
                      task.priority === 'high' ? 'bg-red-100 text-red-800' :
                      task.priority === 'medium' ? 'bg-yellow-100 text-yellow-800' :
                      'bg-green-100 text-green-800'
                    }`}>
                      {task.priority}
                    </span>
                    <span className={`text-xs px-2 py-1 rounded ${
                      task.status === 'done' ? 'bg-green-100 text-green-800' :
                      task.status === 'in_progress' ? 'bg-blue-100 text-blue-800' :
                      'bg-gray-100 text-gray-800'
                    }`}>
                      {task.status.replace('_', ' ')}
                    </span>
                  </div>
                </div>
                <p className="text-sm text-gray-600 mb-2">{task.description}</p>
                <p className="text-xs text-gray-500">
                  {assignedUser ? `Assigned to: ${assignedUser.name}` : 'Unassigned'}
                </p>
              </div>
            );
          })}
        </div>
      )}

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)}>
        <form onSubmit={handleSubmit}>
          <ModalHeader>{editingTask ? 'Edit Task' : 'Create New Task'}</ModalHeader>
          <ModalBody>
            {error && <div className="bg-red-100 text-red-700 p-3 rounded mb-4">{error}</div>}
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-1">Task Title</label>
                <input
                  type="text"
                  required
                  value={formData.title}
                  onChange={e => setFormData({ ...formData, title: e.target.value })}
                  className="w-full border border-gray-300 rounded px-3 py-2"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Description</label>
                <textarea
                  value={formData.description}
                  onChange={e => setFormData({ ...formData, description: e.target.value })}
                  className="w-full border border-gray-300 rounded px-3 py-2"
                  rows={3}
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Assigned To</label>
                <select
                  value={formData.assigned_to}
                  onChange={e => setFormData({ ...formData, assigned_to: e.target.value })}
                  className="w-full border border-gray-300 rounded px-3 py-2"
                >
                  <option value="">Unassigned</option>
                  {users.map(user => (
                    <option key={user.id} value={user.id}>{user.name}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Status</label>
                <select
                  value={formData.status}
                  onChange={e => setFormData({ ...formData, status: e.target.value })}
                  className="w-full border border-gray-300 rounded px-3 py-2"
                >
                  <option value="todo">To Do</option>
                  <option value="in_progress">In Progress</option>
                  <option value="done">Done</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Priority</label>
                <select
                  value={formData.priority}
                  onChange={e => setFormData({ ...formData, priority: e.target.value })}
                  className="w-full border border-gray-300 rounded px-3 py-2"
                >
                  <option value="low">Low</option>
                  <option value="medium">Medium</option>
                  <option value="high">High</option>
                </select>
              </div>
            </div>
          </ModalBody>
          <ModalFooter>
            <button
              type="button"
              onClick={() => setIsModalOpen(false)}
              className="px-4 py-2 border border-gray-300 rounded hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={submitting}
              className="px-4 py-2 bg-primary text-white rounded hover:bg-blue-600 disabled:opacity-50"
            >
              {submitting ? 'Saving...' : editingTask ? 'Update' : 'Create'}
            </button>
          </ModalFooter>
        </form>
      </Modal>
    </div>
  );
}

