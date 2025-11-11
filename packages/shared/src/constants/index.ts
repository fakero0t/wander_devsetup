import { ProjectStatus } from '../types/project';
import { TaskStatus, TaskPriority } from '../types/task';

// Export enums as constants for validation
export const PROJECT_STATUSES = Object.values(ProjectStatus);
export const TASK_STATUSES = Object.values(TaskStatus);
export const TASK_PRIORITIES = Object.values(TaskPriority);

// Re-export enums for convenience
export { ProjectStatus, TaskStatus, TaskPriority };

