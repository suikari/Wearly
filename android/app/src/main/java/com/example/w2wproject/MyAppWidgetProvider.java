package com.example.w2wproject;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;

import android.location.Address;
import android.location.Geocoder;

import android.util.Log;
import android.widget.RemoteViews;

import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LocationServices;

import java.util.List;
import java.io.IOException;
import java.util.concurrent.ExecutionException;

import androidx.work.OneTimeWorkRequest;
import androidx.work.WorkInfo;
import androidx.work.WorkManager;

public class MyAppWidgetProvider extends AppWidgetProvider {
    public static final String ACTION_REFRESH = "com.example.w2wproject.ACTION_REFRESH";
    private static final String TAG = "MyAppWidgetProvider";

    private static final long MIN_UPDATE_INTERVAL = 30 * 60 * 1000L; // 30분

    @Override
    public void onUpdate(Context ctx, AppWidgetManager mgr, int[] ids) {
        super.onUpdate(ctx, mgr, ids);
        Log.d(TAG, "onUpdate 호출, 위젯 ID 수: " + ids.length);

        SharedPreferences prefs = ctx.getSharedPreferences("widget_update_prefs", Context.MODE_PRIVATE);
        long lastUpdate = prefs.getLong("last_update_time", 0);
        long now = System.currentTimeMillis();
        if (now - lastUpdate < MIN_UPDATE_INTERVAL) {
            Log.d(TAG, "최근에 업데이트해서 onUpdate 작업 생략");
            return;
        }
        prefs.edit().putLong("last_update_time", now).apply();

        fetchAndSaveLocationIfNotExists(ctx, false);

        SharedPreferences locationPrefs = ctx.getSharedPreferences("location_prefs", Context.MODE_PRIVATE);
        String locationName = locationPrefs.getString("location_name", "위치 정보 없음");

        for (int id : ids) {
            updateAppWidget(ctx, mgr, id, "로딩 중...", "--°C", locationName);
        }
        startUpdateWork(ctx);
    }

    @Override
    public void onReceive(Context ctx, Intent it) {
        super.onReceive(ctx, it);
        if (ACTION_REFRESH.equals(it.getAction())) {
            Log.d(TAG, "새로고침 버튼 클릭 - WorkManager 실행");
            fetchAndSaveLocationIfNotExists(ctx, true);
            startUpdateWork(ctx);
        }
    }

    private void startUpdateWork(Context ctx) {
        WorkManager workManager = WorkManager.getInstance(ctx);

        try {
            // 이미 실행 중이거나 대기 중인 작업 있는지 확인
            boolean running = false;
            for (WorkInfo info : workManager.getWorkInfosByTag("update_widget_work_tag").get()) {
                if (info.getState() == WorkInfo.State.RUNNING || info.getState() == WorkInfo.State.ENQUEUED) {
                    running = true;
                    break;
                }
            }
            if (!running) {
                OneTimeWorkRequest workRequest = new OneTimeWorkRequest.Builder(UpdateWidgetWorker.class)
                        .addTag("update_widget_work_tag")
                        .build();
                workManager.enqueue(workRequest);
                Log.d(TAG, "WorkManager 작업 신규 등록");
            } else {
                Log.d(TAG, "이미 실행 중인 WorkManager 작업이 있어서 등록하지 않음");
            }
        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
            // 예외 시 안전하게 작업 등록
            OneTimeWorkRequest workRequest = new OneTimeWorkRequest.Builder(UpdateWidgetWorker.class)
                    .addTag("update_widget_work_tag")
                    .build();
            workManager.enqueue(workRequest);
            Log.d(TAG, "예외 발생, WorkManager 작업 등록");
        }
    }

    public static void updateAppWidget(Context ctx, AppWidgetManager mgr, int appId,
                                       String weather, String temp, String locationName) {
        RemoteViews views = new RemoteViews(ctx.getPackageName(), R.layout.widget_layout);

        // 앱 실행 인텐트 설정
        Intent intent = new Intent(ctx, MainActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);

        PendingIntent pendingIntent = PendingIntent.getActivity(
                ctx, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );

        views.setOnClickPendingIntent(R.id.profileImage, pendingIntent); // 혹은 R.id.widget_root_layout

        views.setTextViewText(R.id.weatherText, "날씨: " + weather);
        views.setTextViewText(R.id.tempText, temp);
        views.setTextViewText(R.id.locationText, locationName);  // 위치명 표시

        Intent refreshIntent = new Intent(ctx, MyAppWidgetProvider.class);
        refreshIntent.setAction(ACTION_REFRESH);
        PendingIntent refreshPendingIntent = PendingIntent.getBroadcast(ctx, 0, refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        views.setOnClickPendingIntent(R.id.refreshButton, refreshPendingIntent);

        mgr.updateAppWidget(appId, views);
        Log.d(TAG, "위젯 업데이트 완료 - 날씨: " + weather + ", 온도: " + temp + ", 위치: " + locationName);
    }

    private void fetchAndSaveLocationIfNotExists(Context ctx, boolean flg) {
        SharedPreferences prefs = ctx.getSharedPreferences("location_prefs", Context.MODE_PRIVATE);
        if (prefs.contains("nx") && prefs.contains("ny") && !flg) {
            Log.d("Location", "이미 위치 저장됨, 생략");
            return;
        }

        FusedLocationProviderClient fusedLocationClient = LocationServices.getFusedLocationProviderClient(ctx);
        fusedLocationClient.getLastLocation()
                .addOnSuccessListener(location -> {
                    if (location != null) {
                        double lat = location.getLatitude();
                        double lon = location.getLongitude();

                        String locationName = getLocationName(ctx, lat, lon);

                        int[] xy = convertLonLatToXY(lat, lon);

                        int nx = xy[0];
                        int ny = xy[1];

                        prefs.edit()
                                .putInt("nx", nx)
                                .putInt("ny", ny)
                                .putString("location_name", locationName)
                                .apply();

                        Log.d("Location", "위치 저장됨: nx=" + nx + ", ny=" + ny + ", location_name=" + locationName);
                    } else {
                        Log.w("Location", "위치를 가져올 수 없습니다 (null)");
                    }
                });
    }

    private static String getLocationName(Context ctx, double lat, double lon) {
        Geocoder geocoder = new Geocoder(ctx);
        try {
            List<Address> addresses = geocoder.getFromLocation(lat, lon, 1);
            if (addresses != null && !addresses.isEmpty()) {
                Address address = addresses.get(0);
                String locality = address.getLocality();     // 시
                String subLocality = address.getSubLocality(); // 구 또는 동
                String adminArea = address.getAdminArea();   // 도(광역시)
                Log.d("address", "위치 =" + address);

                return (subLocality != null ? subLocality : "") + " " + (locality != null ? locality : adminArea);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return "알 수 없는 위치";
    }

    public int[] convertLonLatToXY(double lat, double lon) {
        double RE = 6371.00877; // 지구 반경(km)
        double GRID = 5.0;      // 격자 간격(km)
        double SLAT1 = 30.0;    // 투영 위도1(degree)
        double SLAT2 = 60.0;    // 투영 위도2(degree)
        double OLON = 126.0;    // 기준점 경도(degree)
        double OLAT = 38.0;     // 기준점 위도(degree)
        double XO = 43;         // 기준점 X좌표(GRID)
        double YO = 136;        // 기준점 Y좌표(GRID)

        double DEGRAD = Math.PI / 180.0;

        double re = RE / GRID;
        double slat1 = SLAT1 * DEGRAD;
        double slat2 = SLAT2 * DEGRAD;
        double olon = OLON * DEGRAD;
        double olat = OLAT * DEGRAD;

        double sn = Math.tan(Math.PI * 0.25 + slat2 * 0.5) / Math.tan(Math.PI * 0.25 + slat1 * 0.5);
        sn = Math.log(Math.cos(slat1) / Math.cos(slat2)) / Math.log(sn);

        double sf = Math.tan(Math.PI * 0.25 + slat1 * 0.5);
        sf = Math.pow(sf, sn) * Math.cos(slat1) / sn;

        double ro = Math.tan(Math.PI * 0.25 + olat * 0.5);
        ro = re * sf / Math.pow(ro, sn);

        double ra = Math.tan(Math.PI * 0.25 + lat * DEGRAD * 0.5);
        ra = re * sf / Math.pow(ra, sn);

        double theta = lon * DEGRAD - olon;
        if (theta > Math.PI) theta -= 2.0 * Math.PI;
        if (theta < -Math.PI) theta += 2.0 * Math.PI;
        theta *= sn;

        int x = (int) (ra * Math.sin(theta) + XO + 0.5);
        int y = (int) (ro - ra * Math.cos(theta) + YO + 0.5);
        return new int[]{x, y};
    }
}
