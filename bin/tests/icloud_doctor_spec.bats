#!/usr/bin/env bats
# icloud-doctor の回帰テスト
# 実行: bats bin/tests/icloud_doctor_spec.bats

DOCTOR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.local/bin" && pwd)/icloud-doctor"

@test "bash -n: /bin/bash (3.2) で構文 OK" {
	/bin/bash -n "$DOCTOR"
}

@test "bash 3.2 非互換構文を含まない" {
	run grep -En 'declare -A|local -n|mapfile|readarray|\$\{[A-Za-z_]+(\^\^|,,)\}' "$DOCTOR"
	[ "$status" -ne 0 ]
}

@test "daemon_state: ps 出力からデーモンの state/cpu を抽出する" {
	source "$DOCTOR"
	ps_fixture=$'S    0.1 /usr/libexec/bird\nU    2.3 /System/Library/fileproviderd\nR   99.0 /opt/other/birdwatcher'
	result=$(daemon_state bird "$ps_fixture")
	[ "$result" = "S 0.1" ]
	result=$(daemon_state fileproviderd "$ps_fixture")
	[ "$result" = "U 2.3" ]
}

@test "daemon_state: basename 完全一致（birdwatcher を bird と誤認しない）" {
	source "$DOCTOR"
	ps_fixture=$'R   99.0 /opt/other/birdwatcher'
	result=$(daemon_state bird "$ps_fixture")
	[ "$result" = "missing -" ]
}

@test "extract_dataless_paths: ls -lO 出力から dataless 行のパスだけを抽出する" {
	source "$DOCTOR"
	fixture=$'-rw-r--r--  1 user  staff  -                 100  6 12 12:00 /vault/normal.md\n-rw-r--r--  1 user  staff  compressed,dataless  200  7 15  2025 /vault/sub dir/has space.md\n-rw-r--r--  1 user  staff  dataless  300  7 15  2025 /vault/plain.json'
	result=$(printf '%s\n' "$fixture" | extract_dataless_paths)
	expected=$'/vault/sub dir/has space.md\n/vault/plain.json'
	[ "$result" = "$expected" ]
}

@test "check: DATALESS/BIRD/FP 形式の 1 行を出力し last-check に保存する" {
	tmpdir=$(mktemp -d)
	export ICLOUD_DOCTOR_TARGET="$tmpdir" TMPDIR="$tmpdir"
	run bash "$DOCTOR" check
	[ "$status" -eq 0 ]
	[[ "$output" =~ ^DATALESS=[0-9]+\ BIRD=[A-Za-z+]+\ FP=[A-Za-z+]+$ ]]
	[ -f "$tmpdir/icloud-doctor/last-check" ]
	rm -rf "$tmpdir"
}

@test "status: 対象に dataless が無ければ 0 ✓ を表示する" {
	tmpdir=$(mktemp -d)
	touch "$tmpdir/normal.md"
	ICLOUD_DOCTOR_TARGET="$tmpdir" run bash "$DOCTOR" status
	[ "$status" -eq 0 ]
	[[ "$output" == *"dataless 0 ✓"* ]]
	rm -rf "$tmpdir"
}

@test "download --dry-run: brctl を実行しない" {
	tmpdir=$(mktemp -d)
	ICLOUD_DOCTOR_TARGET="$tmpdir" run bash "$DOCTOR" download --dry-run
	[ "$status" -eq 0 ]
	[[ "$output" == *"dataless ファイルはありません"* ]]
	rm -rf "$tmpdir"
}

@test "未知サブコマンドは exit 1" {
	run bash "$DOCTOR" bogus
	[ "$status" -eq 1 ]
}
