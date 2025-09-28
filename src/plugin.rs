// Lyvoxa — Stellar system monitor
// Copyright (c) 2025 Rezky Nightky 2025
// Licensed under GPL-3.0-or-later. See LICENSE in project root.

use ratatui::{Frame, layout::Rect};
/// Lyvoxa Plugin System - Stellar 2.0
///
/// A modular plugin interface for extending Lyvoxa with custom widgets,
/// monitoring sources, and data processors.
///
/// Design principles:
/// - Lightweight: Minimal overhead, optional loading
/// - Safe: Sandboxed execution, resource limits
/// - Extensible: Multiple plugin types for different purposes
/// - Future-ready: AsyncTrait support, hot-reload capability
use std::collections::HashMap;
use std::error::Error;
use std::fmt;

/// Plugin execution results
#[allow(dead_code)]
pub type PluginResult<T> = Result<T, PluginError>;

/// Plugin system errors
#[allow(dead_code)]
#[derive(Debug)]
pub enum PluginError {
    LoadFailed(String),
    InvalidConfig(String),
    RuntimeError(String),
    PermissionDenied(String),
}

impl fmt::Display for PluginError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            PluginError::LoadFailed(msg) => write!(f, "Plugin load failed: {}", msg),
            PluginError::InvalidConfig(msg) => write!(f, "Invalid configuration: {}", msg),
            PluginError::RuntimeError(msg) => write!(f, "Runtime error: {}", msg),
            PluginError::PermissionDenied(msg) => write!(f, "Permission denied: {}", msg),
        }
    }
}

impl Error for PluginError {}

/// Plugin metadata and configuration
#[allow(dead_code)]
#[derive(Debug, Clone)]
pub struct PluginInfo {
    pub name: String,
    pub version: String,
    pub description: String,
    pub author: String,
    pub plugin_type: PluginType,
    pub permissions: Vec<Permission>,
}

/// Plugin types supported by Lyvoxa
#[allow(dead_code)]
#[derive(Debug, Clone, PartialEq)]
pub enum PluginType {
    /// Custom widgets for displaying additional system information
    Widget,
    /// Data processors for metrics transformation/analysis
    DataProcessor,
    /// Monitoring sources for additional system metrics
    MonitoringSource,
    /// Export formats for system snapshots
    Exporter,
    /// Theme extensions for custom color schemes
    Theme,
}

/// Plugin permissions for security control
#[allow(dead_code)]
#[derive(Debug, Clone, PartialEq)]
pub enum Permission {
    ReadSystemMetrics,
    ReadProcessList,
    WriteFiles,
    NetworkAccess,
    ExecuteCommands,
}

/// Data structure for passing system state to plugins
#[allow(dead_code)]
#[derive(Debug, Clone)]
pub struct SystemSnapshot {
    pub cpu_usage: f64,
    pub memory_usage: f64,
    pub network_rx: f64,
    pub network_tx: f64,
    pub process_count: usize,
    pub uptime_seconds: u64,
    pub load_average: (f64, f64, f64),
    pub timestamp: u64,
}

/// Widget plugin trait for custom TUI components
#[allow(dead_code)]
pub trait WidgetPlugin: Send + Sync {
    /// Get plugin information
    fn info(&self) -> PluginInfo;

    /// Initialize the plugin with configuration
    fn initialize(&mut self, config: &HashMap<String, String>) -> PluginResult<()>;

    /// Update internal state with system data
    fn update(&mut self, snapshot: &SystemSnapshot) -> PluginResult<()>;

    /// Render the widget to the terminal
    fn render(&self, area: Rect, frame: &mut Frame);

    /// Handle keyboard input (optional)
    fn handle_key(&mut self, _key: char) -> PluginResult<bool> {
        Ok(false)
    }

    /// Plugin cleanup
    fn shutdown(&mut self) -> PluginResult<()> {
        Ok(())
    }
}

/// Data processor plugin for metrics transformation
#[allow(dead_code)]
pub trait DataProcessorPlugin: Send + Sync {
    fn info(&self) -> PluginInfo;
    fn initialize(&mut self, config: &HashMap<String, String>) -> PluginResult<()>;
    fn process(&self, snapshot: &SystemSnapshot) -> PluginResult<SystemSnapshot>;
}

/// Monitoring source plugin for additional metrics
#[allow(dead_code)]
#[async_trait::async_trait]
pub trait MonitoringSourcePlugin: Send + Sync {
    fn info(&self) -> PluginInfo;
    fn initialize(&mut self, config: &HashMap<String, String>) -> PluginResult<()>;
    async fn collect_metrics(&self) -> PluginResult<HashMap<String, f64>>;
    fn get_metric_names(&self) -> Vec<String>;
}

/// Export plugin for custom snapshot formats
#[allow(dead_code)]
pub trait ExporterPlugin: Send + Sync {
    fn info(&self) -> PluginInfo;
    fn initialize(&mut self, config: &HashMap<String, String>) -> PluginResult<()>;
    fn export(&self, snapshot: &SystemSnapshot, filepath: &str) -> PluginResult<()>;
    fn supported_formats(&self) -> Vec<String>;
}

/// Plugin manager for loading and coordinating plugins
#[allow(dead_code)]
pub struct PluginManager {
    widget_plugins: Vec<Box<dyn WidgetPlugin>>,
    processor_plugins: Vec<Box<dyn DataProcessorPlugin>>,
    monitoring_plugins: Vec<Box<dyn MonitoringSourcePlugin>>,
    export_plugins: Vec<Box<dyn ExporterPlugin>>,
    plugin_configs: HashMap<String, HashMap<String, String>>,
}

#[allow(dead_code)]
impl PluginManager {
    pub fn new() -> Self {
        Self {
            widget_plugins: Vec::new(),
            processor_plugins: Vec::new(),
            monitoring_plugins: Vec::new(),
            export_plugins: Vec::new(),
            plugin_configs: HashMap::new(),
        }
    }

    /// Load a plugin configuration from TOML file
    pub fn load_config(&mut self, _config_path: &str) -> PluginResult<()> {
        // TODO: Implement TOML config parsing
        // This would load plugin definitions, permissions, and settings
        Ok(())
    }

    /// Register a widget plugin
    pub fn register_widget_plugin(&mut self, plugin: Box<dyn WidgetPlugin>) -> PluginResult<()> {
        let info = plugin.info();

        // Security check: validate permissions
        self.validate_permissions(&info)?;

        self.widget_plugins.push(plugin);
        Ok(())
    }

    /// Register a data processor plugin
    pub fn register_processor_plugin(
        &mut self,
        plugin: Box<dyn DataProcessorPlugin>,
    ) -> PluginResult<()> {
        let info = plugin.info();
        self.validate_permissions(&info)?;
        self.processor_plugins.push(plugin);
        Ok(())
    }

    /// Register a monitoring source plugin
    pub fn register_monitoring_plugin(
        &mut self,
        plugin: Box<dyn MonitoringSourcePlugin>,
    ) -> PluginResult<()> {
        let info = plugin.info();
        self.validate_permissions(&info)?;
        self.monitoring_plugins.push(plugin);
        Ok(())
    }

    /// Register an export plugin
    pub fn register_export_plugin(&mut self, plugin: Box<dyn ExporterPlugin>) -> PluginResult<()> {
        let info = plugin.info();
        self.validate_permissions(&info)?;
        self.export_plugins.push(plugin);
        Ok(())
    }

    /// Initialize all loaded plugins
    pub fn initialize_all(&mut self) -> PluginResult<()> {
        for plugin in &mut self.widget_plugins {
            let name = plugin.info().name.clone();
            let config = self.plugin_configs.get(&name).cloned().unwrap_or_default();
            plugin.initialize(&config)?;
        }

        for plugin in &mut self.processor_plugins {
            let name = plugin.info().name.clone();
            let config = self.plugin_configs.get(&name).cloned().unwrap_or_default();
            plugin.initialize(&config)?;
        }

        for plugin in &mut self.monitoring_plugins {
            let name = plugin.info().name.clone();
            let config = self.plugin_configs.get(&name).cloned().unwrap_or_default();
            plugin.initialize(&config)?;
        }

        for plugin in &mut self.export_plugins {
            let name = plugin.info().name.clone();
            let config = self.plugin_configs.get(&name).cloned().unwrap_or_default();
            plugin.initialize(&config)?;
        }

        Ok(())
    }

    /// Update all plugins with new system data
    pub fn update_plugins(&mut self, snapshot: &SystemSnapshot) -> PluginResult<()> {
        // Update widget plugins
        for plugin in &mut self.widget_plugins {
            if let Err(e) = plugin.update(snapshot) {
                eprintln!("Plugin {} update failed: {}", plugin.info().name, e);
            }
        }

        Ok(())
    }

    /// Get list of widget plugins for rendering
    pub fn get_widget_plugins(&self) -> &Vec<Box<dyn WidgetPlugin>> {
        &self.widget_plugins
    }

    /// Process data through all processor plugins
    pub fn process_data(&self, snapshot: SystemSnapshot) -> PluginResult<SystemSnapshot> {
        let mut processed = snapshot;

        for plugin in &self.processor_plugins {
            processed = plugin.process(&processed)?;
        }

        Ok(processed)
    }

    /// Collect metrics from all monitoring plugins
    pub async fn collect_additional_metrics(&self) -> HashMap<String, f64> {
        let mut metrics = HashMap::new();

        for plugin in &self.monitoring_plugins {
            match plugin.collect_metrics().await {
                Ok(plugin_metrics) => {
                    metrics.extend(plugin_metrics);
                }
                Err(e) => {
                    eprintln!(
                        "Plugin {} metrics collection failed: {}",
                        plugin.info().name,
                        e
                    );
                }
            }
        }

        metrics
    }

    /// Export data using specified plugin
    pub fn export_with_plugin(
        &self,
        plugin_name: &str,
        snapshot: &SystemSnapshot,
        filepath: &str,
    ) -> PluginResult<()> {
        for plugin in &self.export_plugins {
            if plugin.info().name == plugin_name {
                return plugin.export(snapshot, filepath);
            }
        }

        Err(PluginError::LoadFailed(format!(
            "Export plugin '{}' not found",
            plugin_name
        )))
    }

    /// Shutdown all plugins gracefully
    pub fn shutdown_all(&mut self) -> PluginResult<()> {
        for plugin in &mut self.widget_plugins {
            if let Err(e) = plugin.shutdown() {
                eprintln!("Plugin {} shutdown error: {}", plugin.info().name, e);
            }
        }

        Ok(())
    }

    /// Validate plugin permissions against system policy
    fn validate_permissions(&self, _info: &PluginInfo) -> PluginResult<()> {
        // TODO: Implement permission validation logic
        // This would check against system security policy
        // and user-defined plugin restrictions

        // For now, allow all permissions (development mode)
        Ok(())
    }
}

impl Default for PluginManager {
    fn default() -> Self {
        Self::new()
    }
}

/// Example: Built-in CPU temperature widget plugin
#[allow(dead_code)]
pub struct CpuTempWidgetPlugin {
    name: String,
    temperature: f64,
}

#[allow(dead_code)]
impl CpuTempWidgetPlugin {
    pub fn new() -> Self {
        Self {
            name: "CPU Temperature Monitor".to_string(),
            temperature: 0.0,
        }
    }
}

impl WidgetPlugin for CpuTempWidgetPlugin {
    fn info(&self) -> PluginInfo {
        PluginInfo {
            name: "cpu_temp_widget".to_string(),
            version: "1.0.0".to_string(),
            description: "Displays CPU temperature with thermal alerts".to_string(),
            author: "Lyvoxa Team".to_string(),
            plugin_type: PluginType::Widget,
            permissions: vec![Permission::ReadSystemMetrics],
        }
    }

    fn initialize(&mut self, _config: &HashMap<String, String>) -> PluginResult<()> {
        // Initialize temperature monitoring
        Ok(())
    }

    fn update(&mut self, _snapshot: &SystemSnapshot) -> PluginResult<()> {
        // TODO: Read actual CPU temperature from /sys/class/thermal/
        // For demo, simulate temperature
        self.temperature = 45.0 + (rand::random::<f64>() * 20.0);
        Ok(())
    }

    fn render(&self, area: Rect, frame: &mut Frame) {
        use ratatui::{
            style::{Color, Style},
            widgets::{Block, Borders, Gauge},
        };

        let color = if self.temperature > 80.0 {
            Color::Red
        } else if self.temperature > 65.0 {
            Color::Yellow
        } else {
            Color::Green
        };

        let gauge = Gauge::default()
            .block(Block::default().borders(Borders::ALL).title("CPU Temp"))
            .gauge_style(Style::default().fg(color))
            .percent((self.temperature.min(100.0)) as u16)
            .label(format!("{:.1}°C", self.temperature));

        frame.render_widget(gauge, area);
    }
}

/// Plugin development utilities
pub mod dev_utils {
    use super::*;

    /// Helper function to create a basic plugin config
    #[allow(dead_code)]
    pub fn create_basic_config() -> HashMap<String, String> {
        let mut config = HashMap::new();
        config.insert("enabled".to_string(), "true".to_string());
        config.insert("update_interval".to_string(), "1000".to_string());
        config
    }

    /// Validate plugin safety before loading
    #[allow(dead_code)]
    pub fn validate_plugin_safety(info: &PluginInfo) -> bool {
        // Basic safety checks
        !info.permissions.contains(&Permission::ExecuteCommands) || info.author.contains("trusted")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_plugin_manager_creation() {
        let manager = PluginManager::new();
        assert_eq!(manager.widget_plugins.len(), 0);
    }

    #[test]
    fn test_cpu_temp_plugin() {
        let plugin = CpuTempWidgetPlugin::new();
        let info = plugin.info();
        assert_eq!(info.plugin_type, PluginType::Widget);
        assert_eq!(info.name, "cpu_temp_widget");
    }
}
