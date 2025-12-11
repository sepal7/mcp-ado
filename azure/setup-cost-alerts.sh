#!/bin/bash

# Azure Cost Alert Setup Script for MCP Server
# Creates budget alerts to monitor monthly spending and prevent exceeding $30/month

RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-rg-00-integration-mcp-dv-eus2-001}"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-71ec4f78-f42e-41e1-96f4-b75a69a53851}"
BUDGET_AMOUNT="${BUDGET_AMOUNT:-30.00}"
BUDGET_NAME="MCP-Server-Monthly-Budget"

echo "🔔 Setting up Azure Cost Alerts for MCP Server Resources"
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "Budget Limit: \$$BUDGET_AMOUNT/month"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not found. Please install Azure CLI first."
    exit 1
fi

echo "✅ Azure CLI found"
echo ""

# Login check
echo "Checking Azure login status..."
if ! az account show &> /dev/null; then
    echo "⚠️  Not logged in. Please run: az login"
    exit 1
fi

# Set subscription
echo "Setting subscription to $SUBSCRIPTION_ID..."
az account set --subscription "$SUBSCRIPTION_ID"
echo "✅ Subscription set"
echo ""

# Check if resource group exists
echo "Checking if resource group exists..."
if ! az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
    echo "⚠️  Resource group '$RESOURCE_GROUP_NAME' does not exist yet."
    echo "   The budget will be created but won't track costs until resources are deployed."
    echo ""
fi

# Prompt for email
read -p "Enter email address for budget alerts: " EMAIL_ADDRESS
if [ -z "$EMAIL_ADDRESS" ]; then
    echo "❌ Email address is required for budget alerts."
    exit 1
fi

# Calculate threshold amounts
THRESHOLD_67=$(echo "scale=2; $BUDGET_AMOUNT * 0.67" | bc)
THRESHOLD_83=$(echo "scale=2; $BUDGET_AMOUNT * 0.83" | bc)

echo ""
echo "Creating budget: $BUDGET_NAME"
echo "  Amount: \$$BUDGET_AMOUNT USD/month"
echo "  Alert thresholds: 67% (\$$THRESHOLD_67), 83% (\$$THRESHOLD_83), 100% (\$$BUDGET_AMOUNT)"
echo ""

# Get start and end dates
START_DATE=$(date +%Y-%m-01)
END_DATE=$(date -d "+1 year" +%Y-%m-01)

# Create budget
echo "Creating budget via Azure CLI..."
az consumption budget create \
    --budget-name "$BUDGET_NAME" \
    --amount "$BUDGET_AMOUNT" \
    --time-grain Monthly \
    --start-date "$START_DATE" \
    --end-date "$END_DATE" \
    --category Cost \
    --resource-group-filter "$RESOURCE_GROUP_NAME" \
    --output none

if [ $? -eq 0 ]; then
    echo "✅ Budget created successfully"
else
    echo "❌ Failed to create budget. Please check your permissions."
    exit 1
fi

# Create notification groups
echo ""
echo "Setting up alert notifications..."

# 67% threshold
echo "  Creating alert at 67% threshold (\$$THRESHOLD_67)..."
az consumption budget notification create \
    --budget-name "$BUDGET_NAME" \
    --notification-name "Warning67Notification" \
    --enabled \
    --operator GreaterThan \
    --threshold 67 \
    --contact-emails "$EMAIL_ADDRESS" \
    --output none 2>/dev/null

# 83% threshold
echo "  Creating alert at 83% threshold (\$$THRESHOLD_83)..."
az consumption budget notification create \
    --budget-name "$BUDGET_NAME" \
    --notification-name "Warning83Notification" \
    --enabled \
    --operator GreaterThan \
    --threshold 83 \
    --contact-emails "$EMAIL_ADDRESS" \
    --output none 2>/dev/null

# 100% threshold
echo "  Creating alert at 100% threshold (\$$BUDGET_AMOUNT)..."
az consumption budget notification create \
    --budget-name "$BUDGET_NAME" \
    --notification-name "ActualNotification" \
    --enabled \
    --operator GreaterThan \
    --threshold 100 \
    --contact-emails "$EMAIL_ADDRESS" \
    --output none 2>/dev/null

echo ""
echo "✅ Cost alerts setup complete!"
echo ""
echo "📊 Budget Summary:"
echo "   Budget Name: $BUDGET_NAME"
echo "   Monthly Limit: \$$BUDGET_AMOUNT USD"
echo "   Resource Group: $RESOURCE_GROUP_NAME"
echo "   Alert Email: $EMAIL_ADDRESS"
echo ""
echo "🔔 You will receive email alerts at:"
echo "   - 67% threshold: \$$THRESHOLD_67 (Early Warning)"
echo "   - 83% threshold: \$$THRESHOLD_83 (Warning)"
echo "   - 100% threshold: \$$BUDGET_AMOUNT (Budget Exceeded)"
echo ""
echo "💡 To view the budget in Azure Portal:"
echo "   https://portal.azure.com/#@/costmanagement/budgets"
echo ""
echo "💡 To check current spending:"
echo "   az consumption budget list --query \"[?name=='$BUDGET_NAME']\""

