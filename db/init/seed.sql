-- Wander Database Seed Script
-- This script is idempotent and can be run multiple times safely

DO $$
DECLARE
  user_count INT;
BEGIN
  -- Idempotency check: Skip if data already exists
  SELECT COUNT(*) INTO user_count FROM information_schema.tables WHERE table_name = 'users';
  
  IF user_count > 0 THEN
    SELECT COUNT(*) INTO user_count FROM users;
    IF user_count > 0 THEN
      RAISE NOTICE 'Database already seeded. Skipping...';
      RETURN;
    END IF;
  END IF;

  -- Drop existing tables if they exist (CASCADE removes dependent objects)
  DROP TABLE IF EXISTS activities CASCADE;
  DROP TABLE IF EXISTS tasks CASCADE;
  DROP TABLE IF EXISTS projects CASCADE;
  DROP TABLE IF EXISTS team_members CASCADE;
  DROP TABLE IF EXISTS teams CASCADE;
  DROP TABLE IF EXISTS users CASCADE;

  -- Create users table
  CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  -- Create teams table
  CREATE TABLE teams (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  -- Create team_members table
  CREATE TABLE team_members (
    id SERIAL PRIMARY KEY,
    team_id INT NOT NULL REFERENCES teams(id) ON DELETE CASCADE ON UPDATE CASCADE,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(team_id, user_id)
  );

  -- Create projects table
  CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    team_id INT NOT NULL REFERENCES teams(id) ON DELETE CASCADE ON UPDATE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  -- Create tasks table
  CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    project_id INT NOT NULL REFERENCES projects(id) ON DELETE CASCADE ON UPDATE CASCADE,
    assigned_to INT REFERENCES users(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'todo',
    priority VARCHAR(50) DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  -- Create activities table
  CREATE TABLE activities (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100),
    entity_id INT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  -- Create indexes for performance
  CREATE INDEX idx_users_email ON users(email);
  CREATE INDEX idx_team_members_user_id ON team_members(user_id);
  CREATE INDEX idx_team_members_team_id ON team_members(team_id);
  CREATE INDEX idx_projects_team_id ON projects(team_id);
  CREATE INDEX idx_tasks_project_id ON tasks(project_id);
  CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
  CREATE INDEX idx_tasks_status ON tasks(status);
  CREATE INDEX idx_activities_user_id ON activities(user_id);
  CREATE INDEX idx_activities_created_at ON activities(created_at);

  -- Insert seed data: Users
  INSERT INTO users (name, email, created_at, updated_at) VALUES
    ('Alice Chen', 'alice@wander.com', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
    ('Bob Martinez', 'bob@wander.com', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
    ('Carol Singh', 'carol@wander.com', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
    ('David Lee', 'david@wander.com', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
    ('Emma Johnson', 'emma@wander.com', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days');

  -- Insert seed data: Teams
  INSERT INTO teams (name, description, created_at, updated_at) VALUES
    ('Frontend Squad', 'Building amazing user interfaces', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
    ('Backend Brigade', 'Powering the backend infrastructure', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days');

  -- Insert seed data: Team Members
  INSERT INTO team_members (team_id, user_id, joined_at) VALUES
    (1, 1, NOW() - INTERVAL '7 days'),  -- Alice → Frontend Squad
    (1, 5, NOW() - INTERVAL '3 days'),  -- Emma → Frontend Squad
    (1, 3, NOW() - INTERVAL '5 days'),  -- Carol → Frontend Squad
    (2, 2, NOW() - INTERVAL '6 days'),  -- Bob → Backend Brigade
    (2, 4, NOW() - INTERVAL '4 days');  -- David → Backend Brigade

  -- Insert seed data: Projects
  INSERT INTO projects (team_id, name, description, status, created_at, updated_at) VALUES
    (1, 'Dashboard Redesign', 'Modernize the main dashboard UI with new design system', 'active', NOW() - INTERVAL '6 days', NOW() - INTERVAL '1 day'),
    (2, 'API v2 Migration', 'Migrate from REST to GraphQL with improved performance', 'active', NOW() - INTERVAL '5 days', NOW() - INTERVAL '2 days');

  -- Insert seed data: Tasks
  INSERT INTO tasks (project_id, assigned_to, title, description, status, priority, created_at, updated_at) VALUES
    (1, 1, 'Design new dashboard layout', 'Create wireframes and mockups for the new dashboard design', 'in_progress', 'high', NOW() - INTERVAL '6 days', NOW() - INTERVAL '1 day'),
    (1, 5, 'Implement responsive grid system', 'Build a flexible grid system that works across all screen sizes', 'todo', 'medium', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
    (1, NULL, 'Add dark mode support', 'Implement dark mode theme with user preferences', 'todo', 'low', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
    (2, 2, 'Design GraphQL schema', 'Define the complete GraphQL schema for API v2', 'done', 'high', NOW() - INTERVAL '5 days', NOW() - INTERVAL '3 days'),
    (2, 2, 'Implement resolvers', 'Build GraphQL resolvers for all queries and mutations', 'in_progress', 'high', NOW() - INTERVAL '4 days', NOW() - INTERVAL '1 day'),
    (2, 4, 'Write migration scripts', 'Create scripts to migrate data from v1 to v2 API', 'todo', 'medium', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days');

  -- Insert seed data: Activities
  INSERT INTO activities (user_id, action, entity_type, entity_id, description, created_at) VALUES
    (1, 'created_task', 'task', 1, 'Alice Chen created task: Design new dashboard layout', NOW() - INTERVAL '6 days'),
    (2, 'completed_task', 'task', 4, 'Bob Martinez completed task: Design GraphQL schema', NOW() - INTERVAL '3 days'),
    (5, 'joined_team', 'team', 1, 'Emma Johnson joined team Frontend Squad', NOW() - INTERVAL '3 days'),
    (1, 'updated_task', 'task', 1, 'Alice Chen started working on task: Design new dashboard layout', NOW() - INTERVAL '2 days'),
    (3, 'joined_team', 'team', 1, 'Carol Singh joined team Frontend Squad', NOW() - INTERVAL '5 days'),
    (4, 'joined_team', 'team', 2, 'David Lee joined team Backend Brigade', NOW() - INTERVAL '4 days'),
    (2, 'created_project', 'project', 2, 'Bob Martinez created project: API v2 Migration', NOW() - INTERVAL '5 days'),
    (2, 'started_task', 'task', 5, 'Bob Martinez started working on task: Implement resolvers', NOW() - INTERVAL '1 day'),
    (5, 'created_task', 'task', 2, 'Emma Johnson created task: Implement responsive grid system', NOW() - INTERVAL '5 days'),
    (1, 'created_project', 'project', 1, 'Alice Chen created project: Dashboard Redesign', NOW() - INTERVAL '6 days');

  -- Success message
  RAISE NOTICE 'Database seeded successfully: 5 users, 2 teams, 2 projects, 6 tasks, 10 activities';

END $$;

