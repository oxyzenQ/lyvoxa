use std::thread;
use std::time::Duration;

mod monitor;
use monitor::SystemMonitor;

fn main() {
    let mut monitor = SystemMonitor::new();
    
    println!("🦀 Rust System Monitor - Simple Version");
    println!("Press Ctrl+C to exit\n");
    
    loop {
        monitor.refresh();
        
        // Clear screen (ANSI escape code)
        print!("\x1B[2J\x1B[1;1H");
        
        // Header
        println!("🦀 Rust System Monitor - Simple Version");
        println!("=====================================\n");
        
        // CPU Information
        let cpu_usage = monitor.get_global_cpu_usage();
        println!("🔥 CPU Usage: {:.1}%", cpu_usage);
        print_bar(cpu_usage, 50);
        
        // Memory Information
        let (used_mem, total_mem) = monitor.get_memory_info();
        let memory_usage = monitor.get_memory_usage_percent();
        println!("\n💾 Memory Usage: {:.1}% ({}/{})", 
                 memory_usage,
                 humansize::format_size(used_mem, humansize::DECIMAL),
                 humansize::format_size(total_mem, humansize::DECIMAL));
        print_bar(memory_usage, 50);
        
        // Top Processes
        println!("\n📊 Top Processes by CPU:");
        println!("{:<8} {:<20} {:<8} {:<12} {:<10}", "PID", "Name", "CPU%", "Memory", "Status");
        println!("{}", "-".repeat(70));
        
        let processes = monitor.get_top_processes(10);
        for process in processes {
            println!("{:<8} {:<20} {:<8.1} {:<12} {:<10}", 
                     process.pid,
                     truncate_string(&process.name, 20),
                     process.cpu_usage,
                     humansize::format_size(process.memory, humansize::DECIMAL),
                     truncate_string(&process.status, 10));
        }
        
        println!("\nPress Ctrl+C to exit...");
        
        // Update every 2 seconds
        thread::sleep(Duration::from_secs(2));
    }
}

fn print_bar(percentage: f64, width: usize) {
    let filled = ((percentage / 100.0) * width as f64) as usize;
    let empty = width - filled;
    
    print!("[");
    for _ in 0..filled {
        print!("█");
    }
    for _ in 0..empty {
        print!("░");
    }
    println!("]");
}

fn truncate_string(s: &str, max_len: usize) -> String {
    if s.len() > max_len {
        format!("{}...", &s[..max_len-3])
    } else {
        s.to_string()
    }
}
