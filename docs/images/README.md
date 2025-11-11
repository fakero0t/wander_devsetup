# Documentation Images

This directory is reserved for diagrams, screenshots, and other visual assets used in documentation.

## Future Additions

Planned diagrams and images:

### Architecture Diagrams
- System overview diagram
- Service communication flow
- Database ER diagram (visual)
- Kubernetes resource map
- Deployment pipeline

### Screenshots
- Dashboard UI
- API health check responses
- Kubernetes dashboard views
- Database schema visualizations

### Network Diagrams
- Service discovery flow
- Port forwarding setup
- Load balancer configuration
- Ingress routing (production)

## Creating Diagrams

**Recommended Tools:**
- **Mermaid**: Markdown-based diagrams (can be embedded in docs)
- **Draw.io**: Visual diagram editor
- **PlantUML**: Text-based UML diagrams
- **Excalidraw**: Hand-drawn style diagrams

**Image Formats:**
- **PNG**: For screenshots and complex diagrams
- **SVG**: For scalable vector graphics
- **Mermaid**: Inline in markdown (no image file needed)

## Usage

To add an image to documentation:

### Markdown
```markdown
![Alt text](./images/diagram-name.png)
```

### With Link
```markdown
[![Alt text](./images/diagram-name.png)](./images/diagram-name.png)
```

### Resized
```html
<img src="./images/diagram-name.png" alt="Alt text" width="600">
```

## Image Guidelines

**File Naming:**
- Use lowercase with hyphens: `system-overview.png`
- Include version if updated frequently: `api-routes-v2.png`
- Be descriptive: `kubernetes-pod-lifecycle.png`

**Image Optimization:**
- Compress PNG files to reduce size
- Use appropriate resolution (no need for 4K diagrams)
- Maintain readability when viewed in GitHub

**Accessibility:**
- Always include descriptive alt text
- Ensure text in images is large enough to read
- Use high contrast colors

## Contributing Images

When adding images:
1. Place in this directory
2. Use descriptive filenames
3. Reference from relevant documentation
4. Add entry to this README
5. Optimize file size before committing

## Image Index

Currently, no images are present. This will be updated as diagrams are added.

### Planned Images

- [ ] `architecture-overview.png` - High-level system architecture
- [ ] `database-er-diagram.png` - Entity relationship diagram
- [ ] `kubernetes-resources.png` - K8s resource hierarchy
- [ ] `service-communication.png` - Inter-service communication flow
- [ ] `dashboard-screenshot.png` - Main dashboard UI
- [ ] `api-endpoints.png` - API route map
- [ ] `deployment-flow.png` - CI/CD and deployment process

---

For now, documentation uses ASCII art and Mermaid diagrams embedded directly in markdown files. This directory is a placeholder for future visual assets.

