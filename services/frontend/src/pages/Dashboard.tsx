import { useState, useEffect } from 'react';
import { apiGet } from '@/api/client';
import { Activity } from '@wander/shared';

export function Dashboard() {
  const [loading, setLoading] = useState(true);
  const [activities, setActivities] = useState<Activity[]>([]);

  useEffect(() => {
    apiGet<Activity[]>('/api/activities')
      .then(setActivities)
      .catch(err => console.error('Failed to fetch activities:', err))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="text-center p-8">Loading...</div>;

  if (activities.length === 0) {
    return (
      <div className="text-center p-8 text-gray-500">
        No recent activity. Create a task to get started!
      </div>
    );
  }

  return (
    <div className="container mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">Dashboard</h1>
      <div className="space-y-2">
        {activities.map(activity => (
          <div key={activity.id} className="bg-white p-4 rounded shadow">
            <p>{activity.description}</p>
            <p className="text-sm text-gray-500">
              {new Intl.DateTimeFormat('en-US', { 
                dateStyle: 'medium', 
                timeStyle: 'short' 
              }).format(new Date(activity.created_at))}
            </p>
          </div>
        ))}
      </div>
    </div>
  );
}

