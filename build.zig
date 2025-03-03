const std = @import("std");
const builtin = @import("builtin");


const flags = .{"-lnx"};
const devkitpro = "/opt/devkitpro";

pub fn build(b: *std.Build) void {
    const mode = b.standardOptimizeOption(.{});
    const target = b.resolveTargetQuery(
        .{
            .cpu_arch = .aarch64,
            .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_a57 },
            .os_tag = .freestanding, .abi = .none
        }
    );
    const obj = b.addObject(.{ .name = "zig-switch", .root_source_file = b.path("src/main.zig"), .target = target, .optimize = mode });
    obj.linkLibC();
    obj.setLibCFile(b.path("libc.txt"));
    obj.addIncludePath(.{ .cwd_relative = devkitpro ++ "/libnx/include" });
    obj.addIncludePath(.{ .cwd_relative = devkitpro ++ "/portlibs/switch/include" });

    const installObj = b.addInstallBinFile(obj.getEmittedBin(), "../zig-switch.o");

    const extension = if (builtin.target.os.tag == .windows) ".exe" else "";
    const elf = b.addSystemCommand(&(.{
        devkitpro ++ "/devkitA64/bin/aarch64-none-elf-gcc" ++ extension,
        "-g",
        "-march=armv8-a+crc+crypto",
        "-mtune=cortex-a57",
        "-mtp=soft",
        "-fPIE",
        "-Wl,-Map,zig-out/zig-switch.map",
        "-specs=" ++ devkitpro ++ "/libnx/switch.specs",
        "zig-out/zig-switch.o",
        "-L" ++ devkitpro ++ "/libnx/lib",
        "-L" ++ devkitpro ++ "/portlibs/switch/lib",
    } ++ flags ++ .{
        "-o",
        "zig-out/zig-switch.elf",
    }));

    const nro = b.addSystemCommand(&.{
        devkitpro ++ "/tools/bin/elf2nro" ++ extension,
        "zig-out/zig-switch.elf",
        "zig-out/zig-switch.nro",
    });

    b.default_step.dependOn(&nro.step);
    nro.step.dependOn(&elf.step);
    elf.step.dependOn(&installObj.step);

}
