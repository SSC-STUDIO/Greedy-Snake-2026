#pragma once

#include <thread>
#include <mutex>
#include <condition_variable>
#include <queue>
#include <atomic>
#include <functional>
#include <future>
#include <vector>
#include <memory>

namespace GreedSnake {

/**
 * @brief 现代化线程池 - 使用 std::jthread (C++20)
 * 
 * 支持任务队列、优雅关闭、异常传播
 */
class ThreadPool {
public:
    explicit ThreadPool(size_t numThreads);
    ~ThreadPool();
    
    // 禁用拷贝和移动
    ThreadPool(const ThreadPool&) = delete;
    ThreadPool& operator=(const ThreadPool&) = delete;
    ThreadPool(ThreadPool&&) = delete;
    ThreadPool& operator=(ThreadPool&&) = delete;
    
    /**
     * @brief 提交任务到线程池
     * @return 返回 future 用于获取结果
     */
    template<typename F, typename... Args>
    [[nodiscard]] auto Enqueue(F&& f, Args&&... args) 
        -> std::future<std::invoke_result_t<F, Args...>> {
        using return_type = std::invoke_result_t<F, Args...>;
        
        auto task = std::make_shared<std::packaged_task<return_type()>>(
            std::bind(std::forward<F>(f), std::forward<Args>(args)...)
        );
        
        std::future<return_type> result = task->get_future();
        {
            std::unique_lock lock(queueMutex_);
            if (stop_) {
                throw std::runtime_error("Cannot enqueue on stopped ThreadPool");
            }
            tasks_.emplace([task](){ (*task)(); });
        }
        condition_.notify_one();
        return result;
    }
    
    /**
     * @brief 获取队列中的任务数量
     */
    [[nodiscard]] size_t PendingTasks() const noexcept {
        std::unique_lock lock(queueMutex_);
        return tasks_.size();
    }
    
    /**
     * @brief 获取工作线程数量
     */
    [[nodiscard]] size_t WorkerCount() const noexcept {
        return workers_.size();
    }
    
    /**
     * @brief 停止线程池
     */
    void Stop() noexcept;
    
    /**
     * @brief 是否正在运行
     */
    [[nodiscard]] bool IsRunning() const noexcept {
        return !stop_.load();
    }
    
private:
    std::vector<std::jthread> workers_;
    std::queue<std::function<void()>> tasks_;
    
    mutable std::mutex queueMutex_;
    std::condition_variable condition_;
    std::atomic<bool> stop_{false};
};

/**
 * @brief 简单的线程管理器 - 替代旧版 ThreadManager
 */
class ThreadManager {
public:
    ThreadManager();
    ~ThreadManager();
    
    // 禁用拷贝
    ThreadManager(const ThreadManager&) = delete;
    ThreadManager& operator=(const ThreadManager&) = delete;
    
    // 启动渲染线程
    void StartRenderThread(std::function<void()> func);
    
    // 启动输入线程
    void StartInputThread(std::function<void()> func);
    
    // 等待所有线程完成
    void JoinAllThreads();
    
    // 检查是否有异常
    [[nodiscard]] bool HasExceptions() const noexcept;
    
    // 检查并重新抛出异常
    void CheckAndRethrowExceptions();
    
private:
    std::unique_ptr<std::jthread> renderThread_;
    std::unique_ptr<std::jthread> inputThread_;
    
    std::exception_ptr renderException_;
    std::exception_ptr inputException_;

    mutable std::mutex exceptionMutex_;
};

} // namespace GreedSnake
