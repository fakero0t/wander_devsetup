import { useState, useEffect } from 'react';
import { apiGet } from '@/api/client';
import { User, Task } from '@wander/shared';

interface UserWithTaskCount extends User {
  taskCount: number;
}

export function Users() {
  const [loading, setLoading] = useState(true);
  const [users, setUsers] = useState<UserWithTaskCount[]>([]);

  useEffect(() => {
    Promise.all([
      apiGet<User[]>('/api/users'),
      apiGet<Task[]>('/api/tasks')
    ])
      .then(([usersData, tasksData]) => {
        const usersWithCounts = usersData.map(user => ({
          ...user,
          taskCount: tasksData.filter(t => t.assigned_to === user.id).length
        }));
        setUsers(usersWithCounts);
      })
      .catch(err => console.error('Failed to fetch users:', err))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-900 text-white flex items-center justify-center pb-20">
        <div>Loading...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-900 text-white pb-20">
    <div className="container mx-auto p-4">
        <h1 className="text-3xl font-bold mb-6">Guests</h1>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {users.map(user => (
            <div key={user.id} className="bg-gray-800 p-6 rounded-lg">
            <h2 className="text-xl font-semibold mb-1">{user.name}</h2>
              <p className="text-sm text-gray-300 mb-2">{user.email}</p>
              <p className="text-xs text-gray-400 mb-2">
                {user.taskCount} review{user.taskCount !== 1 ? 's' : ''}
              </p>
            <p className="text-xs text-gray-500">
              Joined {new Intl.DateTimeFormat('en-US', { 
                dateStyle: 'medium' 
              }).format(new Date(user.created_at))}
            </p>
          </div>
        ))}
        </div>
      </div>
    </div>
  );
}

