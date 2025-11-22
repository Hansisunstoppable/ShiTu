@echo off
echo Starting PaiSmart Go Development Environment...

REM Start Docker services
echo Starting Docker services...
cd /d "E:\Users\Desktop\paismart-go\deployments"
start "Docker Services" /min cmd /c "docker-compose -f docker-compose.yaml up -d && pause"

REM Start Backend Go server
echo Starting Backend Go server...
cd /d "E:\Users\Desktop\paismart-go"
start "Backend Server" cmd /k "go run cmd/server/main.go"

REM Start Frontend development server
echo Starting Frontend development server...
cd /d "E:\Users\Desktop\paismart-go\frontend"
start "Frontend Server" cmd /k "pnpm run dev"

echo.
echo All services started!
echo - Backend: http://localhost:8081
echo - Frontend: http://localhost:3000
echo - Docker services running in background
echo.
echo Press any key to exit this window (services will continue running)
pause >nul