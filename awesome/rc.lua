-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("/home/toby/Dropbox/awesome/themes/solarized/dark/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "urxvt"
editor = os.getenv("EDITOR") or "vi"
editor_cmd = 'gvim'

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
altkey = "Mod1"
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.max,
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
--    awful.layout.suit.spiral,
--    awful.layout.suit.spiral.dwindle,
--    awful.layout.suit.max.fullscreen,
--    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1, 2, 3, 4 }, s, layouts[1])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "Config", editor_cmd .. " " .. awesome.conffile, beautiful.awesome_icon },
   { "Manual", terminal .. " -e man awesome", beautiful.awesome_icon },
   { "Logout", function () awful.util.spawn("oblogout") end, beautiful.awesome_icon },
   { "Restart", awesome.restart, beautiful.awesome_icon, beautiful.awesome_icon }
}

mymainmenu = awful.menu({ items = { { "Awesome", myawesomemenu, beautiful.awesome_icon },
{ "Chrome", function () run_or_raise("chromium", { name = "Chromium" }) end, beautiful.awesome_icon },
{ "Emacs", function () run_or_raise('emacsclient -c -a ""', { name = 'emacs' }) end, beautiful.awesome_icon },
{ "Firefox", function () run_or_raise("firefox", { name = "Mozilla Firefox" }) end, beautiful.awesome_icon },
{ "GIMP", function () run_or_raise("gimp", { name = 'GNU Image Manipulation Program' }) end, beautiful.awesome_icon },
{ "GVim", function () run_or_raise("gvim", { name = 'GVim' }) end, beautiful.awesome_icon },
{ "Office", function () run_or_raise("libreoffice", { name = 'LibreOffice' }) end, beautiful.awesome_icon },
{ "Space", function () run_or_raise("spacefm", { name = "/home/toby" }) end, beautiful.awesome_icon },
{ "Tmux", function () run_or_raise("urxvt -e tmux", { name = "tmux" }) end, beautiful.awesome_icon },
{ "Xterm", function () run_or_raise("xterm", { name = "xterm" }) end, beautiful.awesome_icon },
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock()

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(mytextclock)
    right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "j",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "k",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Tab", awful.tag.history.restore),

    awful.key({ altkey,           }, "k",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ altkey,           }, "j",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ "Control"       }, "Return",
        function ()
            awful.client.focus.history.previous()
            if client.focus then client.focus:raise() end
        end),
    awful.key({ altkey,           }, "m", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ altkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ altkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ altkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ altkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ altkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ altkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ altkey, }, "x", function () run_or_raise("xterm", { name = "xterm" }) end),
    awful.key({ altkey, }, "t", function () run_or_raise("urxvt -e tmux", { name = "tmux" }) end),
    awful.key({ altkey, }, "w", function () run_or_raise("chromium", { name = "Chromium" }) end),
    awful.key({ altkey, }, "c", function () run_or_raise("gcalctool", { name = "Calculator" }) end),
    awful.key({ altkey, }, "v", function () run_or_raise("gvim", { name = "GVIM" }) end),
    awful.key({ altkey, }, "e", function () run_or_raise('emacsclient -c -a ""', { name = "emacs" }) end),
    awful.key({ altkey, }, "f", function () run_or_raise("spacefm", { name = "/home/toby" }) end),
    awful.key({ altkey, "Control" }, "BackSpace", awesome.restart),
    awful.key({ altkey, "Control" }, "Delete", function () awful.util.spawn("oblogout") end),

    awful.key({ altkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ altkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey,           }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ altkey,           }, "Return", function () awful.layout.inc(layouts,  1) end),
    awful.key({ altkey,           }, "BackSpace", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ altkey }, "F2", function () mypromptbox[mouse.screen]:run() end),
    awful.key({ "Control" }, "space", function () awful.util.spawn("dmenu_run -i -p 'dmenu:' -fn '-*-bitocra13-*-*-*-*-*-*-*-*-*-*-*-*' -nb '#002b36' -nf '#ababab' -sb '#ababab' -sf '#000000'")end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end)
)

clientkeys = awful.util.table.join(
    awful.key({                   }, "F11",    function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ altkey,           }, "F4",     function (c) c:kill()                         end),
    awful.key({ modkey,           }, "f",  awful.client.floating.toggle                     ),
    awful.key({ modkey,           }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber))
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ altkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ altkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
		     size_hints_honor = false,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { name = "VLC media player" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { name = "KCalc" },
      properties = { floating = true } },
    { rule = { name = "xterm" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local title = awful.titlebar.widget.titlewidget(c)
        title:buttons(awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                ))

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(title)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- Spawns cmd if no client can be found matching properties
-- If such a client can be found, pop to first tag where it is visible, and give it focus
-- @param cmd the command to execute
-- @param properties a table of properties to match against clients.  Possible entries: any properties of the client object
function run_or_raise(cmd, properties)
 local clients = client.get()
 local focused = awful.client.next(0)
 local findex = 0
 local matched_clients = {}
 local n = 0
   for i, c in pairs(clients) do
--make an array of matched clients
     if match(properties, c) then
        n = n + 1
        matched_clients[n] = c
     if c == focused then
        findex = n
     end
     end
     end
     if n > 0 then
 local c = matched_clients[1]
-- if the focused window matched switch focus to next in list
     if 0 < findex and findex < n then
       c = matched_clients[findex+1]
     end
 local ctags = c:tags()
     if #ctags == 0 then
-- ctags is empty, show client on current tag
 local curtag = awful.tag.selected()
       awful.client.movetotag(curtag, c)
     else
-- Otherwise, pop to first tag client is visible on
       awful.tag.viewonly(ctags[1])
     end
-- And then focus the client
       client.focus = c
                      c:raise()
     return
     end
       awful.util.spawn(cmd)
     end

-- Returns true if all pairs in table1 are present in table2
function match (table1, table2)
  for k, v in pairs(table1) do
     if table2[k] ~= v and not table2[k]:find(v) then
      return false
      end
      end
      return true
      end
-- disable startup-notification globally
local oldspawn = awful.util.spawn
awful.util.spawn = function (s)
oldspawn(s, false)
end
-- Autostart various xorg settings
awful.util.spawn_with_shell("/home/toby/Dropbox/X11/xbin/keyX")
awful.util.spawn_with_shell("/home/toby/Dropbox/X11/xbin/xsetup")
-- Autostart any apps when logging in
awful.util.spawn_with_shell("sleep 5 && nm-applet")
awful.util.spawn_with_shell("sleep 15 && parcellite")
awful.util.spawn_with_shell("sleep 20 && volumeicon")
awful.util.spawn_with_shell("sleep 25 && dropbox-cli start")
awful.util.spawn_with_shell("sleep 60 && caffeine")
awful.util.spawn_with_shell("sleep 90 && /home/toby/Dropbox/X11/xbin/zzzpm")
-- }}}
