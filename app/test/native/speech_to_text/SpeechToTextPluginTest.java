import android.content.Context;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.speech.SpeechRecognizer;
import androidx.core.content.ContextCompat;
import com.csdcorp.speech_to_text.SpeechToTextPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.lang.reflect.Field;
import java.util.*;

/** Executes the actual Gradle-compiled production plugin, not a lifecycle copy.
 * The Android engine, clock and Flutter channel are explicit JVM doubles.
 */
public class SpeechToTextPluginTest {
    static int assertions;
    static void check(boolean value, String message) {
        assertions++;
        if (!value) throw new AssertionError(message);
    }
    static class Reply implements MethodChannel.Result {
        Object value; int calls;
        public void success(Object v) { value=v; calls++; }
        public void error(String c,String m,Object d) { throw new AssertionError(c+": "+m); }
        public void notImplemented() { throw new AssertionError("notImplemented"); }
    }
    static class Fixture {
        final SpeechToTextPlugin plugin=new SpeechToTextPlugin();
        final MethodChannel channel=new MethodChannel(null,"test");
        Fixture() throws Exception {
            set("pluginContext",new Context()); set("channel",channel);
        }
        void set(String name,Object value) throws Exception {
            Field field=SpeechToTextPlugin.class.getDeclaredField(name);
            field.setAccessible(true); field.set(plugin,value);
        }
        Object get(String name) throws Exception {
            Field field=SpeechToTextPlugin.class.getDeclaredField(name);
            field.setAccessible(true); return field.get(plugin);
        }
        Reply call(String name,Map<String,Object> args) {
            Reply result=new Reply(); plugin.onMethodCall(new MethodCall(name,args),result);
            Handler.advance(0); check(result.calls==1,"exactly one reply: "+name); return result;
        }
        Reply initialize() { return call("initialize",Map.of("noBluetooth",true)); }
        Reply listen(int id) { return call("listen",Map.of("captureId",id,"onDevice",true,"listenMode",1,"partialResults",true,"localeId","en_US","listenFor",60000,"pauseFor",60000)); }
        SpeechRecognizer recognizer() { return SpeechRecognizer.created.get(SpeechRecognizer.created.size()-1); }
        List<Object> payloads(String method) {
            List<Object> result=new ArrayList<>();
            for(var event:channel.events) if(event.method().equals(method)) result.add(((Map<?,?>)event.arguments()).get("payload"));
            return result;
        }
        boolean status(String value) { return payloads("notifyStatus").contains(value); }
    }
    static Fixture fresh() throws Exception {
        Handler.reset(); SpeechRecognizer.reset(); ContextCompat.granted=true;
        ContextCompat.bluetoothGranted=false;
        androidx.core.app.ActivityCompat.requested=null;
        Build.VERSION.SDK_INT=33; return new Fixture();
    }
    static Bundle words(String text) {
        Bundle bundle=new Bundle();
        bundle.putStringArrayList("results_recognition",new ArrayList<>(List.of(text)));
        return bundle;
    }
    static void privacyAndCapability() throws Exception {
        for(int sdk:new int[]{21,30,31,33}) {
            Fixture f=fresh(); Build.VERSION.SDK_INT=sdk; SpeechRecognizer.available=false;
            check(Boolean.FALSE.equals(f.initialize().value),"absent local capability");
            check(Boolean.FALSE.equals(f.listen(1).value),"no listen after unavailable init");
            check(SpeechRecognizer.created.isEmpty(),"no recognizer created");
            check(!f.status("listening"),"never false Listening");
            check(SpeechRecognizer.genericCreates==0,"no cloud fallback");
        }
        for(int failure=0;failure<3;failure++) {
            Fixture f=fresh(); check(Boolean.TRUE.equals(f.initialize().value),"ready");
            if(failure==0) SpeechRecognizer.available=false;
            if(failure==1) SpeechRecognizer.failCreate=true;
            if(failure==2) SpeechRecognizer.failStart=true;
            check(Boolean.FALSE.equals(f.listen(7).value),"creation/start race fails closed");
            check(!f.status("listening"),"creation/start failure not Listening");
            check(f.payloads("notifyError").size()==1,"startup error surfaced");
            check(SpeechRecognizer.genericCreates==0,"race never falls back");
        }
        Fixture f=fresh(); f.initialize();
        check(Boolean.FALSE.equals(f.call("listen",Map.of("captureId",1,"onDevice",false,"listenMode",1)).value),"reject non-local request");
        f.call("initialize",Map.of("intentLookup",true)); f.listen(2);
        check(SpeechRecognizer.genericCreates==0,"intent lookup cannot bypass local factory");
        check(Boolean.TRUE.equals(f.recognizer().intent.extras.get("android.speech.extra.PREFER_OFFLINE")),"fresh local intent");
    }
    static void finalAndGeneration() throws Exception {
        Fixture f=fresh(); f.initialize(); f.listen(1);
        SpeechRecognizer first=f.recognizer();
        first.listener.onPartialResults(words("hello"));
        first.listener.onPartialResults(words("hello wonderful"));
        f.call("stop",Map.of());
        check(first.stops==1 && first.destroys==0,"stop retains final listener");
        check(f.status("notListening"),"stop ends listening immediately");
        first.listener.onResults(words("hello wonderful world"));
        check(f.payloads("textRecognition").size()==3,"cumulative partials and final delivered");
        check(f.payloads("textRecognition").get(2).toString().contains("hello wonderful world"),"complete corrected final after stop");
        check(first.destroys==1,"final releases recognizer");
        f.listen(2); SpeechRecognizer second=f.recognizer();
        check(first!=second && first.listener!=second.listener,"no recognizer/listener reuse");
        int size=f.channel.events.size();
        first.listener.onResults(words("stale")); first.listener.onError(5);
        first.listener.onEndOfSpeech(); first.listener.onRmsChanged(8);
        check(size==f.channel.events.size(),"stale callbacks cannot reach new capture");
        second.listener.onPartialResults(words("new words"));
        var event=f.channel.events.get(f.channel.events.size()-1);
        check(((Map<?,?>)event.arguments()).get("captureId").equals(2),"channel carries capture identity");
        Handler.advance(2000);
        check(second.destroys==0,"old finalization cannot destroy new recognizer");
        f.call("cancel",Map.of());
        check(second.cancels==1 && second.destroys==1,"cancel releases recognizer");
        size=f.channel.events.size(); second.listener.onResults(words("late"));
        check(size==f.channel.events.size(),"cancel rejects final");
        f.listen(2); // Deliberately reuse a wire ID; listener identity still fences native callbacks.
        size=f.channel.events.size(); second.listener.onResults(words("same token stale listener"));
        check(size==f.channel.events.size(),"native identity guard survives wire token reuse");
        f.call("cancel",Map.of());
        for(int i=0;i<20;i++) {
            f.listen(100+i); SpeechRecognizer rapid=f.recognizer();
            f.call("stop",Map.of()); f.call("cancel",Map.of());
            check(rapid.stops==1 && rapid.destroys==1,"rapid start/stop/cancel closes exactly once");
        }
    }
    static void endsErrorsCapsAndDispose() throws Exception {
        Fixture f=fresh(); f.initialize(); f.listen(1); SpeechRecognizer r=f.recognizer();
        r.listener.onEndOfSpeech(); check(f.status("notListening"),"early end honest");
        Handler.advance(1999); check(r.destroys==0,"bounded final window remains open");
        Handler.advance(1); check(r.destroys==1 && f.status("doneNoResult"),"empty/silence finalization closes");
        f.listen(2); r=f.recognizer(); r.listener.onError(7);
        check(r.destroys==1 && !f.payloads("notifyError").isEmpty(),"engine error closes capture");
        f.listen(3); r=f.recognizer(); Handler.advance(60000);
        check(r.stops==1 && r.destroys==0,"60s cap stops but preserves final");
        r.listener.onResults(words("capped final")); check(r.destroys==1,"cap final releases");
        f.listen(4); r=f.recognizer(); f.call("stop",Map.of()); f.call("cancel",Map.of());
        check(r.destroys==1,"cancel during finalization releases");
        f.listen(5); SpeechRecognizer latest=f.recognizer(); Handler.advance(2000);
        check(latest.destroys==0,"cancelled final timeout cannot affect next capture");
        f.plugin.onDetachedFromEngine(new io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding(new Context(),null,null,null,null,null,null));
        check(latest.destroys==1,"engine disposal releases");
        int size=f.channel.events.size(); latest.listener.onResults(words("disposed"));
        check(f.channel.events.size()==size,"dispose rejects late results");
        for(boolean error:new boolean[]{false,true}) {
            f=fresh(); f.initialize();
            SpeechRecognizer.endOnStart=!error; SpeechRecognizer.errorOnStart=error;
            f.listen(1); check(!f.status("listening"),"synchronous early end/error never overwritten");
            Handler.advance(2000); check(f.recognizer().destroys==1,"startup termination closes");
        }
    }
    static void localesAndPermission() throws Exception {
        for(int mode=0;mode<4;mode++) {
            Fixture f=fresh(); f.initialize();
            SpeechRecognizer.available=mode!=0;
            SpeechRecognizer.supportError=mode==1; SpeechRecognizer.supportHang=mode==2;
            Reply reply=new Reply(); f.plugin.onMethodCall(new MethodCall("locales",Map.of()),reply);
            Handler.advance(2000);
            check(reply.calls==1,"locales unavailable/error/hang/success replies once");
            if(mode<3) check(((List<?>)reply.value).isEmpty(),"locales fails closed");
            else check(((List<?>)reply.value).size()==1,"only installed local languages reported");
            if(mode>0) check(f.recognizer().destroys==1,"locale probe released");
        }
        Fixture f=fresh(); ContextCompat.granted=false;
        f.set("currentActivity",new android.app.Activity());
        Reply reply=new Reply(); f.plugin.onMethodCall(new MethodCall("initialize",Map.of("noBluetooth",true)),reply);
        Handler.advance(0); check(reply.calls==0,"permission startup waits honestly");
        check(Arrays.equals(androidx.core.app.ActivityCompat.requested,
            new String[]{"android.permission.RECORD_AUDIO"}),"handset dictation never requests Bluetooth permission");
        f.plugin.onDetachedFromEngine(new io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding(new Context(),null,null,null,null,null,null)); Handler.advance(0);
        check(reply.calls==1 && Boolean.FALSE.equals(reply.value),"dispose resolves pending permission");
        f.plugin.onRequestPermissionsResult(28521,new String[]{"android.permission.RECORD_AUDIO"},new int[]{0});
        Handler.advance(0); check(reply.calls==1,"late permission reply cannot double-complete");
    }
    static void handsetBluetoothOptOut() throws Exception {
        Fixture f=fresh(); ContextCompat.bluetoothGranted=true;
        check(Boolean.TRUE.equals(f.initialize().value),"handset ready even when Bluetooth already granted");
        check(Boolean.TRUE.equals(f.get("bluetoothDisabled")),"explicit opt-out overrides granted Bluetooth permission");
        check(f.get("bluetoothAdapter")==null && f.get("bluetoothHeadset")==null,"no Bluetooth profile setup");
        for(int id=1;id<=3;id++) {
            f.listen(id);
            check(f.get("activeBluetooth")==null,"segment does not enter headset voice mode");
            f.call("stop",Map.of()); f.call("cancel",Map.of());
            check(f.get("activeBluetooth")==null,"segment release leaves Bluetooth route alone");
        }
    }
    public static void main(String[] args) throws Exception {
        privacyAndCapability(); finalAndGeneration(); endsErrorsCapsAndDispose(); localesAndPermission(); handsetBluetoothOptOut();
        System.out.println("PASS actual SpeechToTextPlugin JVM lifecycle: "+assertions+" assertions (Android/Flutter doubles; NOT device/acoustic proof)");
    }
}
