#include "ThreadManager.h"
#include "GameState.h"
#include <iostream>
#include <windows.h>
#include <tchar.h>

ThreadManager::ThreadManager() 
    : threadsRunning(false) {
}

ThreadManager::~ThreadManager() {
    StopAllThreads();
    JoinAllThreads();
}

void ThreadManager::SafeThreadExecution(std::function<void()> threadFunction,
                                       std::exception_ptr& exceptionPtr) {
    try {
        threadFunction();
    } catch (...) {
        std::lock_guard<std::mutex> lock(threadMutex);
        exceptionPtr = std::current_exception();
    }
}

void ThreadManager::StartRenderThread(std::function<void()> renderFunction) {
    std::lock_guard<std::mutex> lock(threadMutex);
    
    if (renderThread && renderThread->joinable()) {
        renderThread->join();
    }
    
    renderThreadException = nullptr;
    renderThread = std::make_unique<std::thread>(
        [this, renderFunction]() {
            SafeThreadExecution(renderFunction, renderThreadException);
        });
    
    threadsRunning = true;
}

void ThreadManager::StartInputThread(std::function<void()> inputFunction) {
    std::lock_guard<std::mutex> lock(threadMutex);
    
    if (inputThread && inputThread->joinable()) {
        inputThread->join();
    }
    
    inputThreadException = nullptr;
    inputThread = std::make_unique<std::thread>(
        [this, inputFunction]() {
            SafeThreadExecution(inputFunction, inputThreadException);
        });
    
    threadsRunning = true;
}

void ThreadManager::StartUpdateThread(std::function<void()> updateFunction) {
    std::lock_guard<std::mutex> lock(threadMutex);
    
    if (updateThread && updateThread->joinable()) {
        updateThread->join();
    }
    
    updateThreadException = nullptr;
    updateThread = std::make_unique<std::thread>(
        [this, updateFunction]() {
            SafeThreadExecution(updateFunction, updateThreadException);
        });
    
    threadsRunning = true;
}

void ThreadManager::StopAllThreads() {
    threadsRunning = false;
    GameState::Instance().SetIsGameRunning(false);
}

void ThreadManager::JoinAllThreads() {
    if (renderThread && renderThread->joinable()) {
        renderThread->join();
    }
    
    if (inputThread && inputThread->joinable()) {
        inputThread->join();
    }
    
    if (updateThread && updateThread->joinable()) {
        updateThread->join();
    }

    std::lock_guard<std::mutex> lock(threadMutex);
    threadsRunning = false;
}

bool ThreadManager::HasExceptions() const {
    std::lock_guard<std::mutex> lock(threadMutex);
    return renderThreadException != nullptr ||
           inputThreadException != nullptr ||
           updateThreadException != nullptr;
}

void ThreadManager::CheckAndRethrowExceptions() {
    std::exception_ptr renderException;
    std::exception_ptr inputException;
    std::exception_ptr updateException;
    {
        std::lock_guard<std::mutex> lock(threadMutex);
        renderException = renderThreadException;
        inputException = inputThreadException;
        updateException = updateThreadException;
    }

    if (renderException) {
        try {
            std::rethrow_exception(renderException);
        } catch (const std::exception& e) {
            MessageBox(GetHWnd(), _T("Render thread error occurred"), _T("Error"), MB_OK | MB_ICONERROR);
            OutputDebugStringA(e.what());
        }
    }
    
    if (inputException) {
        try {
            std::rethrow_exception(inputException);
        } catch (const std::exception& e) {
            MessageBox(GetHWnd(), _T("Input thread error occurred"), _T("Error"), MB_OK | MB_ICONERROR);
            OutputDebugStringA(e.what());
        }
    }
    
    if (updateException) {
        try {
            std::rethrow_exception(updateException);
        } catch (const std::exception& e) {
            MessageBox(GetHWnd(), _T("Update thread error occurred"), _T("Error"), MB_OK | MB_ICONERROR);
            OutputDebugStringA(e.what());
        }
    }
}

bool ThreadManager::AreThreadsRunning() const {
    std::lock_guard<std::mutex> lock(threadMutex);
    return threadsRunning;
}
