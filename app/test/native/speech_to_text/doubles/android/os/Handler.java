package android.os;
import java.util.*;
public class Handler {
  private static long now;
  private static final List<Entry> queue = new ArrayList<>();
  private record Entry(Runnable task, long at) {}
  public Handler(Looper looper) {}
  public boolean post(Runnable task) { return postDelayed(task,0); }
  public boolean postDelayed(Runnable task,long delay) { queue.add(new Entry(task,now+delay)); return true; }
  public void removeCallbacks(Runnable task) { queue.removeIf(e -> e.task==task); }
  public static void advance(long delta) {
    long end=now+delta;
    while(true) {
      Entry first=queue.stream().filter(e -> e.at<=end).min(Comparator.comparingLong(e -> e.at)).orElse(null);
      if(first==null) break;
      queue.remove(first); now=first.at; first.task.run();
    }
    now=end;
  }
  public static void reset() { queue.clear(); now=0; }
}
