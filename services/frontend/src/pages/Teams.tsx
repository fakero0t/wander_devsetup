import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { apiGet } from '@/api/client';
import { Team, TeamMember } from '@wander/shared';

interface TeamWithMembers extends Team {
  memberCount: number;
}

export function Teams() {
  const [loading, setLoading] = useState(true);
  const [teams, setTeams] = useState<TeamWithMembers[]>([]);

  useEffect(() => {
    Promise.all([
      apiGet<Team[]>('/api/teams'),
      apiGet<TeamMember[]>('/api/team-members')
    ])
      .then(([teamsData, membersData]) => {
        const teamsWithCounts = teamsData.map(team => ({
          ...team,
          memberCount: membersData.filter(m => m.team_id === team.id).length
        }));
        setTeams(teamsWithCounts);
      })
      .catch(err => console.error('Failed to fetch teams:', err))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-900 text-white flex items-center justify-center pb-20">
        <div>Loading...</div>
      </div>
    );
  }

  if (teams.length === 0) {
    return (
      <div className="min-h-screen bg-gray-900 text-white flex items-center justify-center pb-20">
        <div className="text-center text-gray-400">
          No categories yet.
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-900 text-white pb-20">
      <div className="container mx-auto p-4">
        <h1 className="text-3xl font-bold mb-6">Categories</h1>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {teams.map(team => (
            <div key={team.id} className="bg-gray-800 p-6 rounded-lg">
              <h2 className="text-xl font-semibold mb-2">{team.name}</h2>
              <p className="text-gray-300 mb-4">{team.description}</p>
              <Link 
                to={`/projects`}
                className="text-blue-400 hover:text-blue-300 text-sm font-medium inline-block"
              >
                View Properties →
              </Link>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

