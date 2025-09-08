#!/bin/bash

# CypTrade - FreqTrad Installation Script
# This script installs FreqTrad and all necessary dependencies

set -e

echo "🚀 Installing CypTrade - FreqTrad Configuration..."

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.8 or higher first."
    exit 1
fi

# Check Python version
python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
required_version="3.8"

if [ "$(printf '%s\n' "$required_version" "$python_version" | sort -V | head -n1)" != "$required_version" ]; then
    echo "❌ Python $python_version is installed, but Python $required_version or higher is required."
    exit 1
fi

echo "✅ Python $python_version detected"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "⬆️ Upgrading pip..."
pip install --upgrade pip

# Install TA-Lib (system dependency)
echo "📊 Installing TA-Lib system dependency..."

# Detect OS and install TA-Lib accordingly
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if command -v brew &> /dev/null; then
        echo "🍺 Installing TA-Lib via Homebrew..."
        brew install ta-lib
    else
        echo "❌ Homebrew not found. Please install Homebrew first or install TA-Lib manually."
        exit 1
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if command -v apt-get &> /dev/null; then
        echo "🐧 Installing TA-Lib via apt..."
        sudo apt-get update
        sudo apt-get install -y libta-lib-dev
    elif command -v yum &> /dev/null; then
        echo "🐧 Installing TA-Lib via yum..."
        sudo yum install -y ta-lib-devel
    else
        echo "❌ Package manager not found. Please install TA-Lib manually."
        exit 1
    fi
else
    echo "❌ Unsupported operating system. Please install TA-Lib manually."
    exit 1
fi

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip install -r requirements.txt

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p user_data/logs
mkdir -p user_data/data
mkdir -p user_data/backtest_results
mkdir -p user_data/hyperopt_results

# Copy environment file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "📋 Creating .env file from template..."
    cp env.example .env
    echo "⚠️  Please edit .env file with your API keys before running FreqTrad"
fi

# Test installation
echo "🧪 Testing FreqTrad installation..."
freqtrade --version

echo ""
echo "✅ Installation completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Edit .env file with your exchange API keys"
echo "2. Edit config.json to configure your trading parameters"
echo "3. Run: source venv/bin/activate"
echo "4. Test with: freqtrade trade --config config.json --strategy SampleStrategy"
echo ""
echo "📚 For more information, see README.md"
