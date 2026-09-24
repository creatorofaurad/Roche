//! Roche EVM Security Engine - Alert Dispatcher
//! Webhook, Telegram, Email alert dispatcher with severity escalation.

const std = @import("std");

pub const AlertChannel = enum {
    Webhook,
    Telegram,
    Email,
};

pub const AlertSeverity = enum {
    INFO,
    WARNING,
    CRITICAL,
    EMERGENCY,

    pub fn escalationChannel(self: AlertSeverity) AlertChannel {
        return switch (self) {
            .INFO => .Webhook,
            .WARNING => .Webhook,
            .CRITICAL => .Telegram,
            .EMERGENCY => .Email,
        };
    }
};

pub const Alert = struct {
    protocol: [64]u8 = [_]u8{0} ** 64,
    protocol_len: usize = 0,

    message: [256]u8 = [_]u8{0} ** 256,
    msg_len: usize = 0,

    severity: AlertSeverity = .INFO,

    pub fn getProtocol(self: *const Alert) []const u8 {
        return self.protocol[0..self.protocol_len];
    }

    pub fn getMessage(self: *const Alert) []const u8 {
        return self.message[0..self.msg_len];
    }
};

pub const AlertDispatcher = struct {
    webhook_url: []const u8 = "https://hooks.slack.com/services/test",
    telegram_bot_token: []const u8 = "bot123456789:ABCdef",
    email_recipient: []const u8 = "security@roche.internal",

    pub fn init() AlertDispatcher {
        return .{};
    }

    pub fn dispatch(self: *const AlertDispatcher, alert: *const Alert, out_payload: []u8) !usize {
        const channel = alert.severity.escalationChannel();

        return switch (channel) {
            .Webhook => self.formatWebhookPayload(alert, out_payload),
            .Telegram => self.formatTelegramPayload(alert, out_payload),
            .Email => self.formatEmailPayload(alert, out_payload),
        };
    }

    fn formatWebhookPayload(self: *const AlertDispatcher, alert: *const Alert, out_payload: []u8) usize {
        _ = self;
        return std.fmt.bufPrint(out_payload,
            \\{{"channel":"webhook","severity":"{s}","protocol":"{s}","text":"[ROCHE ALERT] {s}"}}
        , .{ @tagName(alert.severity), alert.getProtocol(), alert.getMessage() }) catch 0;
    }

    fn formatTelegramPayload(self: *const AlertDispatcher, alert: *const Alert, out_payload: []u8) usize {
        return std.fmt.bufPrint(out_payload,
            \\{{"channel":"telegram","bot_token":"{s}","severity":"{s}","protocol":"{s}","text":"🚨 [CRITICAL ALERT] {s}: {s}"}}
        , .{ self.telegram_bot_token, @tagName(alert.severity), alert.getProtocol(), alert.getMessage() }) catch 0;
    }

    fn formatEmailPayload(self: *const AlertDispatcher, alert: *const Alert, out_payload: []u8) usize {
        return std.fmt.bufPrint(out_payload,
            \\{{"channel":"email","to":"{s}","severity":"{s}","subject":"EMERGENCY PROTOCOL BREACH: {s}","body":"{s}"}}
        , .{ self.email_recipient, @tagName(alert.severity), alert.getProtocol(), alert.getMessage() }) catch 0;
    }
};

test "AlertDispatcher escalation mapping" {
    const d = AlertDispatcher.init();
    var alert = Alert{
        .severity = .EMERGENCY,
    };
    const p = "aave";
    @memcpy(alert.protocol[0..p.len], p);
    alert.protocol_len = p.len;
    const msg = "Solvency breached";
    @memcpy(alert.message[0..msg.len], msg);
    alert.msg_len = msg.len;

    var buf: [1024]u8 = undefined;
    const len = try d.dispatch(&alert, &buf);
    try std.testing.expect(len > 0);
    try std.testing.expect(std.mem.indexOf(u8, buf[0..len], "EMERGENCY PROTOCOL BREACH") != null);
}
