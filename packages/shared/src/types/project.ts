export enum ProjectStatus {
  Planning = 'planning',
  Active = 'active',
  Completed = 'completed'
}

export interface Project {
  id: number;
  team_id: number;
  name: string;
  description: string | null;
  status: ProjectStatus;
  created_at: string;
  updated_at: string;
}

