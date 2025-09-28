// Lyvoxa — Stellar system monitor
// Copyright (c) 2025 Rezky Nightky 2025
// Licensed under GPL-3.0-or-later. See LICENSE in project root.

use nix::sys::signal::{Signal, kill};
use nix::unistd::Pid as NixPid;
use procfs::{process::Stat, process::StatM};
use std::ffi::CStr;
use std::time::Instant;
use sysinfo::{CpuExt, PidExt, ProcessExt, System, SystemExt};
#[allow(dead_code)]
pub struct ProcessInfo {
    pub pid: u32,
    pub ppid: Option<u32>,
    pub user: String,
    pub command: String,
    pub cpu_usage: f32,   // percent
    pub mem_bytes: u64,   // RSS bytes
    pub mem_percent: f32, // percent
    pub virt: u64,        // bytes
    pub res: u64,         // bytes
    pub shr: u64,         // bytes (best-effort)
    pub state: char,      // process state, e.g., 'S', 'R'
    pub nice: i64,
    pub priority: i64,
    pub time_total_secs: u64, // utime + stime (seconds)
}

#[allow(dead_code)]
pub struct SystemMonitor {
    system: System,
    cpu_count: usize,
    last_net: Option<NetSnapshot>,
}

#[derive(Clone, Debug)]
#[allow(dead_code)]
struct NetSnapshot {
    ts: Instant,
    rx_total: u64,
    tx_total: u64,
}

#[allow(dead_code)]
impl SystemMonitor {
    pub fn new() -> Self {
        let mut system = System::new_all();
        system.refresh_all();
        let cpu_count = system.cpus().len();

        Self {
            system,
            cpu_count,
            last_net: None,
        }
    }

    pub fn refresh(&mut self) {
        // Refresh at fine granularity for more efficient updates
        self.system.refresh_cpu();
        self.system.refresh_memory();
        self.system.refresh_processes();
        self.system.refresh_disks_list();
        self.system.refresh_disks();
        self.system.refresh_networks();
        // Network snapshot maintained separately via procfs for cumulative totals
    }

    pub fn get_global_cpu_usage(&self) -> f64 {
        self.system.global_cpu_info().cpu_usage() as f64
    }

    pub fn get_cpu_count(&self) -> usize {
        self.cpu_count
    }

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
        let total_mem = self.system.total_memory().max(1);

        let mut processes: Vec<ProcessInfo> = Vec::with_capacity(self.system.processes().len());

        for (pid, proc_) in self.system.processes().iter() {
            let pid_u32 = pid.as_u32();

            // Fallback values
            let mut ppid = None;
            let mut virt = 0u64;
            let mut res = proc_.memory(); // in kB? sysinfo returns kB for memory
            // sysinfo's memory() returns KB; convert to bytes
            res *= 1024;
            let mut shr = 0u64;
            let mut nice = 0i64;
            let mut priority = 0i64;
            let mut state = 'S';
            let mut time_total_secs = 0u64;
            let mut command = if proc_.cmd().is_empty() {
                proc_.name().to_string()
            } else {
                proc_.cmd().join(" ")
            };
            let mut user = String::from("unknown");

            // Try procfs for richer details
            if let Ok(procfs_proc) = procfs::process::Process::new(pid_u32 as i32) {
                if let Ok(stat) = procfs_proc.stat() {
                    fill_from_stat(
                        &stat,
                        &mut ppid,
                        &mut virt,
                        &mut res,
                        &mut shr,
                        &mut nice,
                        &mut priority,
                        &mut state,
                        &mut time_total_secs,
                    );
                }
                if let Ok(statm) = procfs_proc.statm() {
                    fill_from_statm(&statm, &mut virt, &mut res, &mut shr);
                }
                if let Ok(status) = procfs_proc.status() {
                    let u = status.ruid;
                    if let Some(uname) = username_from_uid(u) {
                        user = uname;
                    }
                }
                if let Ok(cmdline) = procfs_proc.cmdline()
                    && !cmdline.is_empty()
                {
                    command = cmdline.join(" ");
                }
            }

            let cpu_usage = proc_.cpu_usage();
            let mem_bytes = res;
            let mem_percent = ((mem_bytes as f64) / (total_mem * 1024u64) as f64 * 100.0) as f32;

            processes.push(ProcessInfo {
                pid: pid_u32,
                ppid,
                user,
                command,
                cpu_usage,
                mem_bytes,
                mem_percent,
                virt,
                res,
                shr,
                state,
                nice,
                priority,
                time_total_secs,
            });
        }

        // Sort by CPU usage (descending)
        processes.sort_by(|a, b| {
            b.cpu_usage
                .partial_cmp(&a.cpu_usage)
                .unwrap_or(std::cmp::Ordering::Equal)
        });
        processes.truncate(limit);
        processes
    }

    pub fn get_process_by_name(&self, name: &str) -> Vec<ProcessInfo> {
        let term = name.to_lowercase();
        self.get_top_processes(usize::MAX)
            .into_iter()
            .filter(|p| {
                p.command.to_lowercase().contains(&term) || p.user.to_lowercase().contains(&term)
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

#[allow(dead_code)]
impl SystemMonitor {
    pub fn get_network_rates(&mut self) -> (f64, f64) {
        // Returns (rx_bytes_per_sec, tx_bytes_per_sec)
        let now = Instant::now();
        let mut rx_total: u64 = 0;
        let mut tx_total: u64 = 0;
        if let Ok(netdev) = procfs::net::dev_status() {
            for (iface, data) in netdev {
                // skip loopback
                if iface == "lo" {
                    continue;
                }
                rx_total = rx_total.saturating_add(data.recv_bytes);
                tx_total = tx_total.saturating_add(data.sent_bytes);
            }
        }

        let rates = if let Some(prev) = &self.last_net {
            let dt = now
                .saturating_duration_since(prev.ts)
                .as_secs_f64()
                .max(0.001);
            let rx_rate = (rx_total.saturating_sub(prev.rx_total)) as f64 / dt;
            let tx_rate = (tx_total.saturating_sub(prev.tx_total)) as f64 / dt;
            (rx_rate, tx_rate)
        } else {
            (0.0, 0.0)
        };

        self.last_net = Some(NetSnapshot {
            ts: now,
            rx_total,
            tx_total,
        });
        rates
    }

    pub fn nice_increase(&self, pid: u32) -> Result<(), String> {
        // F8 Nice+
        // Use libc directly for getpriority/setpriority since nix 0.27 doesn't have them
        unsafe {
            let cur = libc::getpriority(libc::PRIO_PROCESS, pid);
            if libc::getpriority(libc::PRIO_PROCESS, pid) == -1 && *libc::__errno_location() != 0 {
                return Err("Failed to get priority".to_string());
            }
            let new = cur + 1;
            if libc::setpriority(libc::PRIO_PROCESS, pid, new) == -1 {
                return Err("Failed to set priority (try running as root)".to_string());
            }
        }
        Ok(())
    }

    pub fn nice_decrease(&self, pid: u32) -> Result<(), String> {
        // F7 Nice-
        unsafe {
            let cur = libc::getpriority(libc::PRIO_PROCESS, pid);
            if libc::getpriority(libc::PRIO_PROCESS, pid) == -1 && *libc::__errno_location() != 0 {
                return Err("Failed to get priority".to_string());
            }
            let new = cur - 1;
            if libc::setpriority(libc::PRIO_PROCESS, pid, new) == -1 {
                return Err("Failed to set priority (try running as root)".to_string());
            }
        }
        Ok(())
    }

    pub fn kill_process(&self, pid: u32) -> Result<(), String> {
        let npid = NixPid::from_raw(pid as i32);
        kill(npid, Signal::SIGTERM).map_err(format_nix_error)
    }
}

#[allow(dead_code)]
fn format_nix_error(e: nix::Error) -> String {
    match e {
        nix::Error::EPERM => "Operation not permitted (try running as root)".to_string(),
        nix::Error::EINVAL => "Invalid argument".to_string(),
        nix::Error::ESRCH => "Process not found".to_string(),
        nix::Error::EACCES => "Permission denied".to_string(),
        nix::Error::EAGAIN => "Resource temporarily unavailable".to_string(),
        _ => e.to_string(),
    }
}

#[allow(clippy::too_many_arguments)]
fn fill_from_stat(
    stat: &Stat,
    ppid: &mut Option<u32>,
    virt: &mut u64,
    _res: &mut u64,
    _shr: &mut u64,
    nice: &mut i64,
    priority: &mut i64,
    state: &mut char,
    time_total_secs: &mut u64,
) {
    *ppid = Some(stat.ppid as u32);
    *nice = stat.nice;
    *priority = stat.priority;
    *state = stat.state;
    let clk_tck = procfs::ticks_per_second();
    let total_jiffies = stat.utime + stat.stime;
    *time_total_secs = total_jiffies / clk_tck;
    // virt/res from statm instead; here set virt as vsize if available
    *virt = stat.vsize;
}

fn fill_from_statm(statm: &StatM, virt: &mut u64, res: &mut u64, shr: &mut u64) {
    let page_size = procfs::page_size();
    *virt = statm.size.saturating_mul(page_size);
    *res = statm.resident.saturating_mul(page_size);
    *shr = statm.shared.saturating_mul(page_size);
}

#[inline]
fn username_from_uid(uid: u32) -> Option<String> {
    // Safe wrapper around libc::getpwuid (non-reentrant). For our usage (brief lookup in UI thread)
    // this is acceptable. If multi-threaded contention becomes an issue, switch to getpwuid_r.
    unsafe {
        let pwd = libc::getpwuid(uid as libc::uid_t);
        if pwd.is_null() {
            return None;
        }
        let name_ptr = (*pwd).pw_name;
        if name_ptr.is_null() {
            return None;
        }
        let cstr = CStr::from_ptr(name_ptr);
        Some(cstr.to_string_lossy().to_string())
    }
}
