# Development Tools

This page documents the development tools, their configurations, and usage in this environment.

## Code Editor

### VSCode

#### Installed Extensions
- **AI Assistance**:
  - GitHub Copilot
  - GitHub Copilot Chat
  - Cline

- **Git Integration**:
  - GitLens
  - Git Graph
  - GitHub Pull Request
  - GitHub Actions

- **Language Support**:
  - Python Tools (ms-python.python)
  - Python Indent
  - Pylance
  - Terraform (4ops.terraform)
  - TOML (tamasfe.even-better-toml)

- **Utility**:
  - Todo Tree
  - Rainbow CSV
  - Multiline String Editor
  - Workspace

#### Key Features
- AI-powered code completion
- Advanced Git integration
- Multi-language support
- Customized workspace settings

## Infrastructure Tools

### AWS CLI
- Configured with assume role functionality
- Profile management
- SSO integration
- Chrome profile handling

### Docker
- Container management
- Development environments
- Build and deployment

### Packer
- Image building
- Infrastructure templates
- Cloud provider integration

### Ansible
- Configuration management
- Automation
- Infrastructure provisioning

## Version Control

### Git
- GitHub CLI integration
- Custom aliases
- Advanced workflows

### GitHub CLI (gh)
- Repository management
- PR workflows
- Actions management

### SourceTree
- Visual Git interface
- Repository management
- Advanced Git operations

## Development Utilities

### act
- Local GitHub Actions testing
- Workflow validation
- CI/CD development

### direnv
- Environment management
- AWS profile switching
- Project-specific settings

## Database Tools

### DB Browser for SQLite
- Database management
- Query execution
- Schema visualization

## Testing Tools

### Postman/Insomnia
- API testing
- Request management
- Environment variables

## Terminal Tools

### Development-Specific
- `jq` for JSON processing
- `bat` for code viewing
- `ripgrep` for code searching

## Cloud Development

### AWS Tools
```bash
# AWS account aliases
alias staging="assume reepay-staging"
alias dev="assume reepay-dev"
alias prod="assume reepay-prod"
alias pci="assume reepay-pci"
alias sandbox="assume reepay-sandbox"
```

### granted
- AWS role assumption
- Profile management
- SSO integration

## Workflow Integration

### Shell-GPT
- Code assistance
- Command generation
- Documentation help

### GitHub Copilot
- Code completion
- Documentation generation
- Problem solving

## Best Practices

### Project Organization
- Consistent directory structure
- Clear naming conventions
- Documentation standards

### Development Workflow
1. Use direnv for environment management
2. Leverage AI tools for efficiency
3. Maintain consistent formatting
4. Follow security best practices

### Security
- AWS role separation
- Environment isolation
- Credential management

## See Also
- [Installation Guide](Installation-Guide.md)
- [ZSH Core Configuration](ZSH-Core-Configuration.md)
- [ZSH Tools and Plugins](ZSH-Tools-and-Plugins.md)
