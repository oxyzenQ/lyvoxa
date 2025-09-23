use sysinfo::{CpuExt, PidExt, ProcessExt, System, SystemExt};

#[derive(Debug, Clone)]
pub struct ProcessInfo {
    pub pid: u32,
    pub name: String,
    pub cpu_usage: f32,
    pub memory: u64,
    pub status: String,
}

pub struct SystemMonitor {
    system: System,
    #[allow(dead_code)]
    cpu_count: usize,
}

impl SystemMonitor {
    pub fn new() -> Self {
        let mut system = System::new_all();
        system.refresh_all();
        let cpu_count = system.cpus().len();

        Self { system, cpu_count }
    }

    pub fn refresh(&mut self) {
        self.system.refresh_all();
    }

    pub fn get_global_cpu_usage(&self) -> f64 {
        self.system.global_cpu_info().cpu_usage() as f64
    }

    #[allow(dead_code)]
    pub fn get_cpu_count(&self) -> usize {
        self.cpu_count
    }

    #[allow(dead_code)]
    pub fn get_cpu_usage_per_core(&self) -> Vec<f32> {
        self.system
            .cpus()
            .iter()
            .map(|cpu| cpu.cpu_usage())
            .collect()
    }

    pub fn get_memory_info(&self) -> (u64, u64) {
        let used = self.system.used_memory();
        let total = self.system.total_memory();
        (used, total)
    }

    pub fn get_memory_usage_percent(&self) -> f64 {
        let (used, total) = self.get_memory_info();
        if total > 0 {
            (used as f64 / total as f64) * 100.0
        } else {
            0.0
        }
    }

    #[allow(dead_code)]
    pub fn get_swap_info(&self) -> (u64, u64) {
        let used = self.system.used_swap();
        let total = self.system.total_swap();
        (used, total)
    }

    #[allow(dead_code)]
    pub fn get_uptime(&self) -> u64 {
        self.system.uptime()
    }

    #[allow(dead_code)]
    pub fn get_load_average(&self) -> (f64, f64, f64) {
        let load_avg = self.system.load_average();
        (load_avg.one, load_avg.five, load_avg.fifteen)
    }

    #[allow(dead_code)]
    pub fn get_process_count(&self) -> usize {
        self.system.processes().len()
    }

    pub fn get_top_processes(&self, limit: usize) -> Vec<ProcessInfo> {
        let mut processes: Vec<ProcessInfo> = self
            .system
            .processes()
            .iter()
            .map(|(pid, process)| ProcessInfo {
                pid: pid.as_u32(),
                name: process.name().to_string(),
                cpu_usage: process.cpu_usage(),
                memory: process.memory(),
                status: format!("{:?}", process.status()),
            })
            .collect();

        // Sort by CPU usage (descending)
        processes.sort_by(|a, b| b.cpu_usage.partial_cmp(&a.cpu_usage).unwrap());

        // Take only the top N processes
        processes.truncate(limit);
        processes
    }

    #[allow(dead_code)]
    pub fn get_process_by_name(&self, name: &str) -> Vec<ProcessInfo> {
        self.system
            .processes()
            .iter()
            .filter(|(_, process)| process.name().to_lowercase().contains(&name.to_lowercase()))
            .map(|(pid, process)| ProcessInfo {
                pid: pid.as_u32(),
                name: process.name().to_string(),
                cpu_usage: process.cpu_usage(),
                memory: process.memory(),
                status: format!("{:?}", process.status()),
            })
            .collect()
    }

    #[allow(dead_code)]
    pub fn get_system_info(&self) -> SystemInfo {
        SystemInfo {
            hostname: self
                .system
                .host_name()
                .unwrap_or_else(|| "Unknown".to_string()),
            kernel_version: self
                .system
                .kernel_version()
                .unwrap_or_else(|| "Unknown".to_string()),
            os_version: self
                .system
                .long_os_version()
                .unwrap_or_else(|| "Unknown".to_string()),
            uptime: self.get_uptime(),
            load_average: self.get_load_average(),
            process_count: self.get_process_count(),
        }
    }
}

#[derive(Debug)]
#[allow(dead_code)]
pub struct SystemInfo {
    pub hostname: String,
    pub kernel_version: String,
    pub os_version: String,
    pub uptime: u64,
    pub load_average: (f64, f64, f64),
    pub process_count: usize,
}
