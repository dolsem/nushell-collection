# pb - Progress Bar for pipes

let update_interval: duration = 0.5sec
export def pb [
  total_items?: int
]: any -> any {
  tee {
    each { date now }
    | enumerate
    | reduce -f {
        prev_count: 0
        first_ts: null
        prev_ts: null
        last_update: null
    } {|row, state|

      let count = $row.index
      let ts = $row.item

      if $state.first_ts == null {
        return {
          prev_count: $count
          first_ts: $ts
          prev_ts: $ts
          last_update: $ts
        }
      }

      let dt_print = $ts - $state.last_update

      if $dt_print >= $update_interval {
        let count_delta = $count - $state.prev_count
        let dt = ($ts - $state.prev_ts) / 1sec
        let elapsed = ($ts - $state.first_ts) // 1sec

        let speed = ($count_delta / $dt)
        let tpi = ($dt / $count_delta)

        mut out = $"($count)  ($elapsed | into string)s  ( $speed | into string --decimals 2 ) item/s  ( $tpi | into string --decimals 6 ) s/item"

        if $total_items != null {
          let pct = ($count * 100.0 / $total_items)
          let est_total_time = ($total_items / $speed)
          let eta = ($est_total_time - $elapsed)

          let width = 20
          let filled = ($pct * $width / 100 | math round)

          let filled_bar = (seq 1 $filled        | each { "█" } | str join)
          let empty_bar  = (seq 1 ($width - $filled) | each { "░" } | str join)
          let bar = $"[($filled_bar)($empty_bar)]"

          let extra = $"  ($bar)  ( $pct | into string --decimals 2 )%  ( $eta | into string --decimals 1 )s ETA"
          $out = $out + $extra
        }

        print -n $"\r($out)"

        return {
          prev_count: $count
          first_ts: $state.first_ts
          prev_ts: $ts
          last_update: $ts
        }
      }

      return {
        prev_count: $count
        first_ts: $state.first_ts
        prev_ts: $ts
        last_update: $state.last_update
      }
    }
  }
}