# GitHub Account Information

## Current Configuration

**Repository:** https://github.com/sepal7/mcp-ado.git  
**Current Git User:** sepal7  
**Current Git Email:** (configure as needed)

## About node_modules

**✅ `node_modules` is correctly excluded from GitHub** - This is the standard practice!

### Why node_modules is not in GitHub:

1. **Size**: Can contain thousands of files and be hundreds of MB
2. **Redundancy**: Dependencies are defined in `package.json` and `package-lock.json`
3. **Platform-specific**: Binaries may differ between Windows/Mac/Linux
4. **Standard Practice**: All Node.js projects exclude it

### How it works:

- `.gitignore` includes `node_modules/` (already configured ✅)
- When someone clones the repo, they run `npm install` to get dependencies
- `package.json` and `package-lock.json` ensure everyone gets the same versions

**This is correct and expected behavior!**

## GitHub Account Options

### Current Account: sepal7 (Personal)

✅ **Repository is now under personal account:** https://github.com/sepal7/mcp-ado.git
**Pros:**
- Personal ownership
- Not tied to company
- Better for public/open source projects

**Cons:**
- Need to change remote URL
- Need to update git config
- May need to transfer repository

### Recommended: Use Personal Account for Public Repos

Since this is a public/open source project, using your personal GitHub account is recommended.

## How to Switch to Personal Account

### Step 1: Create/Use Personal GitHub Account

1. If you don't have a personal GitHub account:
   - Go to: https://github.com/signup
   - Sign up with your personal email
   - Choose a username

2. If you already have a personal account:
   - Use that account

### Step 2: Create New Repository (or Transfer)

**Option A: Create New Repository**
```powershell
# On GitHub, create a new repository under your personal account
# Then update remote:
cd C:\adoAzure\Github\mcp-ado
git remote set-url origin https://github.com/sepal7/mcp-ado.git
git push -u origin main
```

**Option B: Transfer Existing Repository**
- Go to repository settings on GitHub
- Scroll to "Danger Zone"
- Click "Transfer ownership"
- Enter your personal GitHub username

### Step 3: Update Git Config (Optional)

```powershell
git config user.name "sepal7"
git config user.email "sepal7@users.noreply.github.com"

# Or set globally:
git config --global user.name "sepal7"
git config --global user.email "sepal7@users.noreply.github.com"
```

### Step 4: Update package.json

Update the repository URL in `package.json` to match your personal account.

## Recommendation

**For public/open source projects:** Use personal GitHub account  
**For company/internal projects:** Use company GitHub account

Since this MCP server is generic and public, **I recommend using your personal account**.

