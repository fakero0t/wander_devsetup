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

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-900 text-white flex items-center justify-center pb-20">
        <div>Loading...</div>
      </div>
    );
  }
  if (!project) {
    return (
      <div className="min-h-screen bg-gray-900 text-white flex items-center justify-center pb-20">
        <div className="text-center text-red-400">Property not found</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-900 text-white pb-20">
    <div className="container mx-auto p-4">
        <div className="bg-gray-800 p-6 rounded-lg mb-6">
          <h1 className="text-3xl font-bold mb-2">{project.name}</h1>
          <p className="text-gray-300 mb-4">{project.description}</p>
        <span className={`text-xs px-2 py-1 rounded ${
            project.status === 'active' ? 'bg-green-500 text-white' :
            project.status === 'planning' ? 'bg-yellow-500 text-white' :
            'bg-gray-600 text-white'
        }`}>
          {project.status}
        </span>
      </div>

      <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold">Reviews</h2>
        <button
          onClick={() => handleOpenModal()}
            className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
        >
            Add Review
        </button>
      </div>

      {tasks.length === 0 ? (
          <div className="text-center p-8 text-gray-400">
            No reviews for this property yet.
        </div>
      ) : (
        <div className="space-y-3">
          {tasks.map(task => {
            const assignedUser = users.find(u => u.id === task.assigned_to);
            return (
              <div 
                key={task.id} 
                  className="bg-gray-800 p-4 rounded-lg hover:bg-gray-750 cursor-pointer transition-colors"
                onClick={() => handleOpenModal(task)}
              >
                <div className="flex justify-between items-start mb-2">
                  <h3 className="font-semibold">{task.title}</h3>
                  <div className="flex gap-2">
                    <span className={`text-xs px-2 py-1 rounded ${
                        task.priority === 'high' ? 'bg-yellow-500 text-white' :
                        task.priority === 'medium' ? 'bg-blue-500 text-white' :
                        'bg-green-500 text-white'
                    }`}>
                      {task.priority}
                    </span>
                    <span className={`text-xs px-2 py-1 rounded ${
                        task.status === 'done' ? 'bg-green-500 text-white' :
                        task.status === 'in_progress' ? 'bg-blue-500 text-white' :
                        'bg-gray-600 text-white'
                    }`}>
                      {task.status.replace('_', ' ')}
                    </span>
                  </div>
                </div>
                  <p className="text-sm text-gray-300 mb-2">{task.description}</p>
                  <p className="text-xs text-gray-400">
                    {assignedUser ? `By: ${assignedUser.name}` : 'Anonymous'}
                </p>
              </div>
            );
          })}
        </div>
      )}

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)}>
        <form onSubmit={handleSubmit}>
          <ModalHeader>{editingTask ? 'Edit Review' : 'Add Review'}</ModalHeader>
          <ModalBody>
            {error && <div className="bg-red-100 text-red-700 p-3 rounded mb-4">{error}</div>}
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-1 text-gray-700">Review Title</label>
                <input
                  type="text"
                  required
                  value={formData.title}
                  onChange={e => setFormData({ ...formData, title: e.target.value })}
                  className="w-full border border-gray-300 rounded px-3 py-2"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1 text-gray-700">Review</label>
                <textarea
                  value={formData.description}
                  onChange={e => setFormData({ ...formData, description: e.target.value })}
                  className="w-full border border-gray-300 rounded px-3 py-2"
                  rows={3}
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1 text-gray-700">Reviewer</label>
                <select
                  value={formData.assigned_to}
                  onChange={e => setFormData({ ...formData, assigned_to: e.target.value })}
                  className="w-full border border-gray-300 rounded px-3 py-2"
                >
                  <option value="">Anonymous</option>
                  {users.map(user => (
                    <option key={user.id} value={user.id}>{user.name}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium mb-1 text-gray-700">Status</label>
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
                <label className="block text-sm font-medium mb-1 text-gray-700">Rating</label>
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
              className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
            >
              {submitting ? 'Saving...' : editingTask ? 'Update' : 'Create'}
            </button>
          </ModalFooter>
        </form>
      </Modal>
      </div>
    </div>
  );
}

