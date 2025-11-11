import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { apiGet, apiPost } from '@/api/client';
import { Project, Team, ProjectStatus } from '@wander/shared';
import { Modal } from '@/components/Modal';
import { ModalHeader } from '@/components/ModalHeader';
import { ModalBody } from '@/components/ModalBody';
import { ModalFooter } from '@/components/ModalFooter';

export function Projects() {
  const [loading, setLoading] = useState(true);
  const [projects, setProjects] = useState<Project[]>([]);
  const [teams, setTeams] = useState<Team[]>([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [formData, setFormData] = useState({ name: '', description: '', team_id: '', status: 'planning' });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = () => {
    Promise.all([
      apiGet<Project[]>('/api/projects'),
      apiGet<Team[]>('/api/teams')
    ])
      .then(([projectsData, teamsData]) => {
        setProjects(projectsData);
        setTeams(teamsData);
      })
      .catch(err => console.error('Failed to fetch data:', err))
      .finally(() => setLoading(false));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError('');
    try {
      await apiPost('/api/projects', {
        ...formData,
        team_id: parseInt(formData.team_id)
      });
      setIsModalOpen(false);
      setFormData({ name: '', description: '', team_id: '', status: 'planning' });
      fetchData();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create project');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) return <div className="text-center p-8">Loading...</div>;

  const projectsByTeam = teams.map(team => ({
    team,
    projects: projects.filter(p => p.team_id === team.id)
  }));

  return (
    <div className="container mx-auto p-4">
      <div className="flex justify-between items-center mb-4">
        <h1 className="text-2xl font-bold">Projects</h1>
        <button
          onClick={() => setIsModalOpen(true)}
          className="bg-primary text-white px-4 py-2 rounded hover:bg-blue-600"
        >
          New Project
        </button>
      </div>

      {projects.length === 0 ? (
        <div className="text-center p-8 text-gray-500">
          No projects yet. Create one to begin.
        </div>
      ) : (
        projectsByTeam.map(({ team, projects }) => (
          projects.length > 0 && (
            <div key={team.id} className="mb-6">
              <h2 className="text-xl font-semibold mb-3">{team.name}</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {projects.map(project => (
                  <Link 
                    key={project.id}
                    to={`/projects/${project.id}`}
                    className="bg-white p-4 rounded shadow hover:shadow-lg transition-shadow"
                  >
                    <h3 className="font-semibold mb-2">{project.name}</h3>
                    <p className="text-sm text-gray-600 mb-2">{project.description}</p>
                    <span className={`text-xs px-2 py-1 rounded ${
                      project.status === 'active' ? 'bg-green-100 text-green-800' :
                      project.status === 'planning' ? 'bg-yellow-100 text-yellow-800' :
                      'bg-gray-100 text-gray-800'
                    }`}>
                      {project.status}
                    </span>
                  </Link>
                ))}
              </div>
            </div>
          )
        ))
      )}

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)}>
        <form onSubmit={handleSubmit}>
          <ModalHeader>Create New Project</ModalHeader>
          <ModalBody>
            {error && <div className="bg-red-100 text-red-700 p-3 rounded mb-4">{error}</div>}
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-1">Project Name</label>
                <input
                  type="text"
                  required
                  value={formData.name}
                  onChange={e => setFormData({ ...formData, name: e.target.value })}
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
                <label className="block text-sm font-medium mb-1">Team</label>
                <select
                  required
                  value={formData.team_id}
                  onChange={e => setFormData({ ...formData, team_id: e.target.value })}
                  className="w-full border border-gray-300 rounded px-3 py-2"
                >
                  <option value="">Select a team</option>
                  {teams.map(team => (
                    <option key={team.id} value={team.id}>{team.name}</option>
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
                  <option value="planning">Planning</option>
                  <option value="active">Active</option>
                  <option value="completed">Completed</option>
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
              {submitting ? 'Creating...' : 'Create'}
            </button>
          </ModalFooter>
        </form>
      </Modal>
    </div>
  );
}

