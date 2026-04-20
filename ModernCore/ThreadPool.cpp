#include "ThreadPool.h"

namespace GreedSnake {

ThreadPool::ThreadPool(size_t numThreads) {
    workers_.reserve(numThreads);
    for (size_t i = 0; i < numThreads; ++i) {
        workers_.emplace_back([this] {
            while (true) {
                std::function<void()> task;
                {
                    std::unique_lock lock(queueMutex_);
                    condition_.wait(lock, [this] {
                        return stop_.load() || !tasks_.empty();
                    });
                    if (stop_.load() && tasks_.empty()) {
                        return;
                    }
                    task = std::move(tasks_.front());
                    tasks_.pop();
                }
                task();
            }
        });
    }
}

ThreadPool::~ThreadPool() {
    Stop();
}

void ThreadPool::Stop() noexcept {
    {
        std::unique_lock lock(queueMutex_);
        stop_.store(true);
    }
    condition_.notify_all();
    for (auto& worker : workers_) {
        if (worker.joinable()) {
            worker.join();
        }
    }
}

// ThreadManager 实现
ThreadManager::ThreadManager() = default;

ThreadManager::~ThreadManager() {
    JoinAllThreads();
}

void ThreadManager::StartRenderThread(std::function<void()> func) {
    std::unique_lock lock(exceptionMutex_);
    renderThread_ = std::make_unique<std::jthread>([this, func = std::move(func)]() {
        try {
            func();
        } catch (...) {
            std::lock_guard lock(exceptionMutex_);
            renderException_ = std::current_exception();
        }
    });
}

void ThreadManager::StartInputThread(std::function<void()> func) {
    std::unique_lock lock(exceptionMutex_);
    inputThread_ = std::make_unique<std::jthread>([this, func = std::move(func)]() {
        try {
            func();
        } catch (...) {
            std::lock_guard lock(exceptionMutex_);
            inputException_ = std::current_exception();
        }
    });
}

void ThreadManager::JoinAllThreads() {
    if (renderThread_ && renderThread_->joinable()) {
        renderThread_->join();
    }
    if (inputThread_ && inputThread_->joinable()) {
        inputThread_->join();
    }
}

bool ThreadManager::HasExceptions() const noexcept {
    std::lock_guard lock(exceptionMutex_);
    return renderException_ || inputException_;
}

void ThreadManager::CheckAndRethrowExceptions() {
    std::lock_guard lock(exceptionMutex_);
    if (renderException_) {
        std::rethrow_exception(renderException_);
    }
    if (inputException_) {
        std::rethrow_exception(inputException_);
    }
}

} // namespace GreedSnake
