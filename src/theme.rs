use ratatui::style::Color;

#[derive(Copy, Clone, Debug, Eq, PartialEq)]
pub enum ThemeKind {
    Light,
    Dark,
    Stellar,
    Matrix,
}

#[derive(Copy, Clone, Debug)]
pub struct Theme {
    pub fg: Color,
    pub bg: Color,
    pub accent: Color,
    pub cpu: Color,
    pub mem: Color,
    pub net_rx: Color,
    pub net_tx: Color,
    pub table_header: Color,
    pub selection_bg: Color,
}

impl Theme {
    pub fn palette(kind: ThemeKind) -> Self {
        match kind {
            ThemeKind::Light => Self {
                fg: Color::Black,
                bg: Color::Gray,
                accent: Color::Blue,
                cpu: Color::Yellow,
                mem: Color::Green,
                net_rx: Color::Cyan,
                net_tx: Color::Magenta,
                table_header: Color::Blue,
                selection_bg: Color::White,
            },
            ThemeKind::Dark => Self {
                fg: Color::White,
                bg: Color::Black,
                accent: Color::Cyan,
                cpu: Color::Yellow,
                mem: Color::Green,
                net_rx: Color::LightCyan,
                net_tx: Color::LightMagenta,
                table_header: Color::Cyan,
                selection_bg: Color::DarkGray,
            },
            ThemeKind::Stellar => Self {
                fg: Color::Rgb(200, 210, 255),
                bg: Color::Rgb(5, 8, 20),
                accent: Color::Rgb(120, 100, 255),
                cpu: Color::Rgb(255, 210, 90),
                mem: Color::Rgb(120, 255, 160),
                net_rx: Color::Rgb(120, 240, 255),
                net_tx: Color::Rgb(255, 120, 240),
                table_header: Color::Rgb(140, 120, 255),
                selection_bg: Color::Rgb(20, 25, 50),
            },
            ThemeKind::Matrix => Self {
                fg: Color::Rgb(180, 255, 180),
                bg: Color::Rgb(0, 10, 0),
                accent: Color::Rgb(0, 255, 120),
                cpu: Color::Rgb(160, 255, 160),
                mem: Color::Rgb(0, 200, 80),
                net_rx: Color::Rgb(100, 255, 180),
                net_tx: Color::Rgb(0, 180, 120),
                table_header: Color::Rgb(0, 255, 120),
                selection_bg: Color::Rgb(0, 40, 0),
            },
        }
    }
}
