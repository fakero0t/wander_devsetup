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
  const [properties, setProperties] = useState<Project[]>([]);
  const [categories, setCategories] = useState<Team[]>([]);
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
      .then(([propertiesData, categoriesData]) => {
        setProperties(propertiesData);
        setCategories(categoriesData);
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
      setError(err instanceof Error ? err.message : 'Failed to create property');
    } finally {
      setSubmitting(false);
    }
  };

  const getLocation = (property: Project) => {
    if (property.name.includes('Crystal Palms')) return 'BOLIVAR PENINSULA, TEXAS';
    if (property.name.includes('Wimberley')) return 'WIMBERLEY, TEXAS';
    if (property.name.includes('Concan')) return 'SABINAL, TEXAS';
    if (property.name.includes('Port Aransas')) return 'PORT ARANSAS, TEXAS';
    if (property.name.includes('Lake Travis')) return 'AUSTIN, TEXAS';
    if (property.name.includes('Marfa')) return 'MARFA, TEXAS';
    const category = categories.find(c => c.id === property.team_id);
    return `${category?.name.toUpperCase() || 'TEXAS'}, TEXAS`;
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-900 text-white flex items-center justify-center pb-20">
        <div>Loading...</div>
      </div>
    );
  }

  const propertiesByCategory = categories.map(category => ({
    category,
    properties: properties.filter(p => p.team_id === category.id)
  }));

  return (
    <div className="min-h-screen bg-gray-900 text-white pb-20">
      <div className="container mx-auto p-4">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-3xl font-bold">All Properties</h1>
          <button
            onClick={() => setIsModalOpen(true)}
            className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
          >
            Add Property
          </button>
        </div>

        {properties.length === 0 ? (
          <div className="text-center p-8 text-gray-400">
            No properties yet. Add one to begin.
          </div>
        ) : (
          propertiesByCategory.map(({ category, properties }) => (
            properties.length > 0 && (
              <div key={category.id} className="mb-8">
                <h2 className="text-xl font-semibold mb-4">{category.name}</h2>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {properties.map(property => {
                    const location = getLocation(property);
                    return (
                      <Link 
                        key={property.id}
                        to={`/projects/${property.id}`}
                        className="bg-gray-800 rounded-lg overflow-hidden hover:bg-gray-750 transition-colors"
                      >
                        <div className="w-full h-48 bg-gradient-to-br from-gray-700 to-gray-600 relative">
                          <div className="absolute top-3 left-3 bg-yellow-500 text-gray-900 text-xs font-semibold px-2 py-1 rounded">
                            Available
                          </div>
                          <div className="absolute top-3 right-3 bg-gray-900 bg-opacity-50 rounded-full p-2">
                            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                            </svg>
                          </div>
                        </div>
                        <div className="p-4">
                          <div className="text-xs text-gray-400 mb-1">{location}</div>
                          <h3 className="text-lg font-semibold mb-2">{property.name}</h3>
                          <p className="text-sm text-gray-300 mb-3 line-clamp-2">{property.description}</p>
                          <div className="flex items-center space-x-4 text-sm text-gray-400">
                            <div className="flex items-center">
                              <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                                <path d="M10.394 2.08a1 1 0 00-.788 0l-7 3a1 1 0 000 1.84L5.25 8.051a.999.999 0 01.356-.257l4-1.714a1 1 0 11.788 1.838L7.667 9.088l1.94.831a1 1 0 00.787 0l7-3a1 1 0 000-1.838l-7-3zM3.31 9.397L5 10.12v4.102a8.969 8.969 0 00-1.05-.174 1 1 0 01-.89-.89 11.115 11.115 0 01.25-3.762zM9.3 16.573A9.026 9.026 0 007 14.935v-3.957l1.818.78a3 3 0 002.364 0l5.508-2.361a11.026 11.026 0 01.25 3.762 1 1 0 01-.89.89 8.968 8.968 0 00-5.35 2.524 1 1 0 01-1.4 0zM6 18a1 1 0 001-1v-2.065a8.935 8.935 0 00-2-.712V17a1 1 0 001 1z" />
                              </svg>
                              <span>3</span>
                            </div>
                            <div className="flex items-center">
                              <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                                <path d="M9 6a3 3 0 11-6 0 3 3 0 016 0zM17 6a3 3 0 11-6 0 3 3 0 016 0zM12.93 17c.046-.327.07-.66.07-1a6.97 6.97 0 00-1.5-4.33A5 5 0 0119 16v1h-6.07zM6 11a5 5 0 015 5v1H1v-1a5 5 0 015-5z" />
                              </svg>
                              <span>8-10</span>
                            </div>
                          </div>
                        </div>
                      </Link>
                    );
                  })}
                </div>
              </div>
            )
          ))
        )}

        <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)}>
          <form onSubmit={handleSubmit}>
            <ModalHeader>Add New Property</ModalHeader>
            <ModalBody>
              {error && <div className="bg-red-100 text-red-700 p-3 rounded mb-4">{error}</div>}
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium mb-1 text-gray-700">Property Name</label>
                  <input
                    type="text"
                    required
                    value={formData.name}
                    onChange={e => setFormData({ ...formData, name: e.target.value })}
                    className="w-full border border-gray-300 rounded px-3 py-2"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-1 text-gray-700">Description</label>
                  <textarea
                    value={formData.description}
                    onChange={e => setFormData({ ...formData, description: e.target.value })}
                    className="w-full border border-gray-300 rounded px-3 py-2"
                    rows={3}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-1 text-gray-700">Category</label>
                  <select
                    required
                    value={formData.team_id}
                    onChange={e => setFormData({ ...formData, team_id: e.target.value })}
                    className="w-full border border-gray-300 rounded px-3 py-2"
                  >
                    <option value="">Select a category</option>
                    {categories.map(category => (
                      <option key={category.id} value={category.id}>{category.name}</option>
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
                className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
              >
                {submitting ? 'Adding...' : 'Add Property'}
              </button>
            </ModalFooter>
          </form>
        </Modal>
      </div>
    </div>
  );
}
