# Publishing the Package

This guide explains how to publish `@sepal7/mcp-ado-server` to GitHub Packages or npm.

## Option 1: Publish to GitHub Packages (Recommended)

GitHub Packages is integrated with your repository and makes it easy to publish alongside your code.

### Prerequisites

1. **GitHub Personal Access Token (PAT)** with `write:packages` and `read:packages` scopes
   - Create at: https://github.com/settings/tokens/new
   - Select scopes: `write:packages`, `read:packages`, `repo`

### Steps

1. **Configure npm to use GitHub Packages:**

   ```powershell
   # Create .npmrc file in your home directory
   echo "@sepal7:registry=https://npm.pkg.github.com" | Out-File -FilePath "$env:USERPROFILE\.npmrc" -Encoding utf8
   ```

2. **Authenticate with GitHub Packages:**

   ```powershell
   # Login to npm with your GitHub token
   npm login --registry=https://npm.pkg.github.com --scope=@sepal7
   ```
   
   When prompted:
   - Username: `sepal7`
   - Password: Your GitHub PAT token
   - Email: sepal7@users.noreply.github.com

3. **Publish the package:**

   ```powershell
   cd C:\adoAzure\Github\mcp-ado
   npm publish
   ```

4. **Verify publication:**
   - Check: https://github.com/sepal7/mcp-ado/packages

### Installing from GitHub Packages

Users can install your package with:

```bash
npm install @sepal7/mcp-ado-server
```

**Note:** Users need to authenticate with GitHub Packages to install private packages, or make the package public in repository settings.

---

## Option 2: Publish to npm (Public Registry)

To publish to the public npm registry:

### Prerequisites

1. **npm account** - Sign up at: https://www.npmjs.com/signup
2. **Update package.json** - Change name from `@sepal7/mcp-ado-server` to `mcp-ado-server` (or check if name is available)

### Steps

1. **Login to npm:**

   ```powershell
   npm login
   ```

2. **Verify you're logged in:**

   ```powershell
   npm whoami
   ```

3. **Check package name availability:**

   ```powershell
   npm search mcp-ado-server
   ```

4. **Publish:**

   ```powershell
   cd C:\adoAzure\Github\mcp-ado
   npm publish --access public
   ```

5. **Verify:**
   - Check: https://www.npmjs.com/package/mcp-ado-server

---

## Package Configuration

The package is configured with:
- **Name:** `@sepal7/mcp-ado-server` (for GitHub Packages)
- **Version:** `1.0.0` (matches release tag)
- **Main:** `server.js`
- **Files included:** Only essential files (see `.npmignore`)

## Updating the Package

To publish a new version:

1. Update version in `package.json`
2. Create a new git tag: `git tag v1.0.1`
3. Push tag: `git push origin v1.0.1`
4. Publish: `npm publish`

---

## Troubleshooting

**Error: "UNABLE_TO_GET_ISSUER_CERT_LOCALLY" (SSL Certificate Issue)**
This is common in corporate networks. Fix by creating `.npmrc` file in project root:
```
@sepal7:registry=https://npm.pkg.github.com
strict-ssl=false
```
Or globally: `npm config set strict-ssl false`

**Error: "You do not have permission to publish"**
- Make sure you're authenticated: `npm whoami`
- Check PAT has `write:packages` scope (GitHub Packages)
- Verify package name matches your GitHub username scope

**Error: "Package name already exists"**
- For npm: Choose a different name or check if you own the existing package
- For GitHub Packages: The package is scoped to your account, so this shouldn't happen

**Error: "401 Unauthorized"**
- Re-authenticate: `npm login`
- Check your PAT token is valid and has correct scopes

