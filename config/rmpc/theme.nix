{ config }:
let
  colors = config.lib.stylix.colors;
in
''
  #![enable(implicit_some)]
  #![enable(unwrap_newtypes)]
  #![enable(unwrap_variant_newtypes)]

  (
      default_album_art_path: None,
      show_song_table_header: true,
      draw_borders: true,
      border_type: "Rounded", 
      browser_column_widths: [20, 30, 60],
      symbols: (song: "󰎈 ", dir: "󰉋 ", marker: " ", ellipsis: "..."),
      
      text_color: "#${colors.base05}", 
      
      tab_bar: (
          enabled: true,
          active_style: (bg: "#${colors.base08}", fg: "#${colors.base00}"),
          inactive_style: (fg: "#${colors.base03}"),
      ),

      highlighted_item_style: (fg: "#${colors.base0D}", modifiers: "Bold"), 
      current_item_style: (fg: "#${colors.base05}", bg: "#${colors.base02}", modifiers: "Bold"), 
      
      borders_style: (fg: "#${colors.base03}"), 
      highlight_border_style: (fg: "#${colors.base08}"), 

      progress_bar: (
          symbols: ["═", "◉", "─"], 
          track_style: (fg: "#${colors.base03}"), 
          elapsed_style: (fg: "#${colors.base08}"), 
          thumb_style: (fg: "#${colors.base0B}"), 
      ),

      scrollbar: (
          symbols: ["│", "┃", "▲", "▼"], 
          track_style: (fg: "#${colors.base01}"),   
          ends_style: (fg: "#${colors.base03}"),
          thumb_style: (fg: "#${colors.base08}"),   
      ),

      browser_song_format: [
          (kind: Group([(kind: Property(Track)), (kind: Text(" "))])),
          (
              kind: Group([
                  (kind: Property(Title)),
                  (kind: Text(" ")),
                  (kind: Property(Artist), style: (fg: "#${colors.base0E}")), 
              ]),
              default: (kind: Property(Filename))
          ),
      ],

      song_table_format: [
          (
              prop: (
                  kind: Property(Title), 
                  style: (fg: "#${colors.base05}", modifiers: "Bold"), 
                  highlighted_item_style: (fg: "#${colors.base05}", modifiers: "Bold"),
                  default: (kind: Property(Filename), style: (fg: "#${colors.base03}"))
              ),
              width: "45%",
          ),
          (
              prop: (
                  kind: Property(Artist), 
                  style: (fg: "#${colors.base0C}"), 
                  default: (kind: Text("Unknown"), style: (fg: "#${colors.base03}"))
              ),
              width: "35%",
          ),
          (
              prop: (kind: Property(Duration), style: (fg: "#${colors.base03}")), 
              width: "20%",
              alignment: Right,
          ),
      ],

      header: (
          rows: [
              (
                  left: [
                      (kind: Property(Status(StateV2(playing_label: "", paused_label: "⏸", stopped_label: "⏹"))), style: (fg: "#${colors.base08}", modifiers: "Bold")),
                      (kind: Text(" ")),
                  ],
                  center: [
                      (kind: Property(Song(Title)), style: (fg: "#${colors.base05}", modifiers: "Bold"),
                          default: (kind: Property(Song(Filename)), style: (fg: "#${colors.base05}", modifiers: "Bold"))
                      )
                  ],
                  right: [
                      (kind: Text(" "), style: (fg: "#${colors.base0A}")),
                      (kind: Property(Status(Volume)), style: (fg: "#${colors.base0A}", modifiers: "Bold")),
                      (kind: Text("%"), style: (fg: "#${colors.base0A}"))
                  ]
              ),
              (
                  left: [
                      (kind: Property(Status(Elapsed)), style: (fg: "#${colors.base08}")),
                      (kind: Text(" / "), style: (fg: "#${colors.base03}")),
                      (kind: Property(Status(Duration)), style: (fg: "#${colors.base03}")),
                  ],
                  center: [
                      (kind: Property(Song(Artist)), style: (fg: "#${colors.base0C}"), 
                          default: (kind: Text("Unknown Artist"), style: (fg: "#${colors.base03}"))
                      ),
                  ],
                  right: [
                      (
                          kind: Property(Widget(States(
                              active_style: (fg: "#${colors.base08}", modifiers: "Bold"), 
                              separator_style: (fg: "#${colors.base03}")))
                          ),
                          style: (fg: "#${colors.base03}")
                      ),
                  ]
              ),
          ],
      ),
      
      layout: Split(
          direction: Vertical,
          panes: [
              (size: "4", borders: "BOTTOM", pane: Pane(Header)),
              (size: "3", borders: "NONE", pane: Pane(Tabs)),
              (size: "100%", pane: Pane(TabContent)),
              (size: "2", borders: "TOP", pane: Pane(ProgressBar)),
          ],
      ),
  )
''
