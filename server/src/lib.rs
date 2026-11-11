// SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
// SPDX-License-Identifier: EUPL-1.2

use spacetimedb::{reducer, table, Identity, ReducerContext, Table};

// Every client receives every row, so one client must not be able to send huge strings.
const MAX_ANIMATION_LEN: usize = 64;
const MAX_LEVEL_LEN: usize = 256;

// One row per connected player. Positions are trusted beyond being finite numbers.
// The Godot codegen needs a primary key on every table.
#[table(accessor = net_player, public)]
pub struct NetPlayer {
    #[primary_key]
    identity: Identity,
    x: f32,
    y: f32,
    z: f32,
    flip: bool,
    animation: String,
    // Level scene path, clients hide players that are in another level.
    level: String,
}

// Upsert, so there is no connect hook and the row appears with the first update.
#[reducer]
pub fn update_net_player(
    ctx: &ReducerContext,
    x: f32,
    y: f32,
    z: f32,
    flip: bool,
    animation: String,
    level: String,
) -> Result<(), String> {
    if !(x.is_finite() && y.is_finite() && z.is_finite()) {
        return Err("position must be finite".to_string());
    }
    if animation.len() > MAX_ANIMATION_LEN {
        return Err(format!("animation is longer than {MAX_ANIMATION_LEN} bytes"));
    }
    if level.len() > MAX_LEVEL_LEN {
        return Err(format!("level is longer than {MAX_LEVEL_LEN} bytes"));
    }
    let me = ctx.sender();
    let row = NetPlayer {
        identity: me,
        x,
        y,
        z,
        flip,
        animation,
        level,
    };
    if ctx.db.net_player().identity().find(me).is_some() {
        ctx.db.net_player().identity().update(row);
    } else {
        ctx.db.net_player().insert(row);
    }
    Ok(())
}

#[reducer(client_disconnected)]
pub fn on_disconnect(ctx: &ReducerContext) {
    ctx.db.net_player().identity().delete(ctx.sender());
}
