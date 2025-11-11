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

  if (loading) return <div className="text-center p-8">Loading...</div>;

  if (teams.length === 0) {
    return (
      <div className="text-center p-8 text-gray-500">
        No teams yet.
      </div>
    );
  }

  return (
    <div className="container mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">Teams</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {teams.map(team => (
          <div key={team.id} className="bg-white p-4 rounded shadow">
            <h2 className="text-xl font-semibold mb-2">{team.name}</h2>
            <p className="text-gray-600 mb-2">{team.description}</p>
            <p className="text-sm text-gray-500">
              {team.memberCount} member{team.memberCount !== 1 ? 's' : ''}
            </p>
            <Link 
              to={`/projects?team=${team.id}`}
              className="text-primary hover:underline text-sm mt-2 inline-block"
            >
              View Projects →
            </Link>
          </div>
        ))}
      </div>
    </div>
  );
}

