#!/bin/bash

# ================================
# 🔐 Secure Git Auto-Push Script
# ================================

set -e  # Exit on any error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Secure Git Auto-Push ===${NC}"
echo ""

# -------------------------------
# Check if git is installed
# -------------------------------
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git is not installed. Please install Git first.${NC}"
    exit 1
fi

# -------------------------------
# Input Section
# -------------------------------
read -p "📝 Enter commit message: " COMMIT_MSG
if [ -z "$COMMIT_MSG" ]; then
    echo -e "${RED}❌ Commit message is required.${NC}"
    exit 1
fi

read -p "🌐 Enter remote URL (HTTPS or SSH): " REMOTE_URL
if [ -z "$REMOTE_URL" ]; then
    echo -e "${RED}❌ Remote URL is required.${NC}"
    exit 1
fi

# Prevent token usage in URL
if [[ "$REMOTE_URL" == *"@"*"github.com"* && "$REMOTE_URL" == *"http"* ]]; then
    echo -e "${RED}❌ Do NOT include tokens in the URL.${NC}"
    echo -e "${YELLOW}Use:${NC} https://github.com/user/repo.git"
    echo -e "${YELLOW}Or SSH:${NC} git@github.com:user/repo.git"
    exit 1
fi

read -p "📂 Files to add (default '.'): " FILES
FILES=${FILES:-"."}

echo ""
echo -e "${YELLOW}⚙️ Running workflow...${NC}"
echo ""

# -------------------------------
# Step 1: Init repo
# -------------------------------
if [ ! -d ".git" ]; then
    echo "[1/7] Initializing repository..."
    git init
else
    echo "[1/7] Repo already initialized ✓"
fi

# -------------------------------
# Step 2: .gitignore setup
# -------------------------------
if [ ! -f ".gitignore" ]; then
    echo "[2/7] Creating .gitignore..."
    cat > .gitignore << EOF
# Sensitive files
git-auto-push.sh
*.env
*.pem
*.key

# OS files
.DS_Store
Thumbs.db

# Logs
*.log
EOF
    git add .gitignore
    echo "✓ .gitignore created"
else
    echo "[2/7] .gitignore exists ✓"
fi

# -------------------------------
# Step 3: Add files
# -------------------------------
echo "[3/7] Staging files..."
git add $FILES

# -------------------------------
# Step 4: Commit
# -------------------------------
if git diff --cached --quiet; then
    echo "[4/7] No changes to commit ✓"
else
    echo "[4/7] Committing..."
    git commit -m "$COMMIT_MSG"
    echo "✓ Commit created"
fi

# -------------------------------
# Step 5: Remote setup
# -------------------------------
if git remote get-url origin &>/dev/null; then
    echo "[5/7] Remote exists ✓"
else
    echo "[5/7] Adding remote..."
    git remote add origin "$REMOTE_URL"
    echo "✓ Remote added"
fi

# -------------------------------
# Step 6: Branch handling
# -------------------------------
echo "[6/7] Checking branch..."

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$CURRENT_BRANCH" != "main" ]; then
    if git show-ref --verify --quiet refs/heads/main; then
        git checkout main
    else
        git checkout -b main
    fi
    echo "✓ Switched to main"
else
    echo "✓ Already on main"
fi

# -------------------------------
# Step 7: Push
# -------------------------------
echo "[7/7] Pushing..."

if git push -u origin main; then
    echo -e "${GREEN}✓ Push successful!${NC}"
else
    echo -e "${RED}❌ Push failed!${NC}"
    exit 1
fi

# -------------------------------
# Done
# -------------------------------
echo ""
echo -e "${GREEN}=== Done ===${NC}"
echo "Commit : $COMMIT_MSG"
echo "Remote : $REMOTE_URL"
echo "Files  : $FILES"
