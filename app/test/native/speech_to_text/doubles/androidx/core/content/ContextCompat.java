package androidx.core.content; import android.content.Context;
public class ContextCompat { public static boolean granted=true; public static int checkSelfPermission(Context c,String p){return p.equals("android.permission.RECORD_AUDIO")&&granted?0:-1;} }
