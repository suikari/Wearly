package com.example.w2wproject;

import android.appwidget.AppWidgetManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.SharedPreferences;

import android.util.Log;

import androidx.annotation.NonNull;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;

import okhttp3.HttpUrl;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

public class UpdateWidgetWorker extends Worker {
    private static final String TAG = "UpdateWidgetWorker";

    private static final String API_URL = "https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getUltraSrtFcst?";
    private static final String SERVICE_KEY = "S3AZfm2Egyrf+p1ufP5MBZEaDoowYupZS0xInJ2xpkPtDO06W7EbQcvOk0eTUmOYgxYf3K4IAOpXSU+carvkfA==";

    public UpdateWidgetWorker(@NonNull Context context, @NonNull WorkerParameters params) {
        super(context, params);
    }

    private String getClosestFcstTime() {
        Calendar cal = Calendar.getInstance();
        int hour = cal.get(Calendar.HOUR_OF_DAY);
        int closestHour = (hour / 1) * 1;  // 정시 단위 내림
        return String.format("%02d00", closestHour);
    }

    @NonNull
    @Override
    public Result doWork() {
        Log.d(TAG, "doWork 시작");

        Context context = getApplicationContext();
        AppWidgetManager mgr = AppWidgetManager.getInstance(context);
        int[] ids = mgr.getAppWidgetIds(new ComponentName(context, MyAppWidgetProvider.class));
        Log.d(TAG, "업데이트 대상 위젯 개수: " + ids.length);

        String weather = "--";
        String temp = "--°C";
        String targetFcstTime = getClosestFcstTime();
        Log.d(TAG, "타겟 fcstTime: " + targetFcstTime);

        try {
            String json = fetchWeatherJson();
            //Log.d(TAG, "API 응답 JSON: " + json);
            Log.d(TAG, "API 응답: " + json); // 이 줄 추가

            JSONObject obj = new JSONObject(json);
            JSONObject response = obj.getJSONObject("response");
            JSONObject body = response.getJSONObject("body");
            JSONObject itemsObject = body.getJSONObject("items");
            JSONArray items = itemsObject.getJSONArray("item");

            for (int i = 0; i < items.length(); i++) {
                JSONObject it = items.getJSONObject(i);
                String category = it.getString("category");
                String fcstTime = it.getString("fcstTime");

                if (!fcstTime.equals(targetFcstTime)) continue;

                if (category.equals("T1H")) {
                    temp = it.getString("fcstValue") + "°C";
                } else if (category.equals("SKY")) {
                    String skyValue = it.getString("fcstValue");
                    weather = skyValue.equals("1") ? "맑음" : "흐림/비";
                }
            }

            Log.d(TAG, "파싱 완료 - 날씨: " + weather + ", 온도: " + temp);

        } catch (Exception e) {
            Log.e(TAG, "날씨 정보 가져오기 실패", e);
            return Result.success(); // 실패해도 종료
        }

        SharedPreferences prefs = getApplicationContext().getSharedPreferences("location_prefs", Context.MODE_PRIVATE);
        String locationName = prefs.getString("location_name", "위치 정보 없음");


        for (int appId : ids) {
            MyAppWidgetProvider.updateAppWidget(context, mgr, appId, weather, temp, locationName);
        }
        Log.d(TAG, "위젯 업데이트 완료");

        return Result.success();
    }

    private String fetchWeatherJson() throws IOException {
        SharedPreferences prefs = getApplicationContext().getSharedPreferences("location_prefs", Context.MODE_PRIVATE);
        int nx = prefs.getInt("nx", 62);  // 기본값: 서울
        int ny = prefs.getInt("ny", 125);

        HttpUrl url = HttpUrl.parse(API_URL).newBuilder()
                .addQueryParameter("serviceKey", SERVICE_KEY)
                .addQueryParameter("dataType", "JSON")
                .addQueryParameter("base_date", getBaseDate())
                .addQueryParameter("base_time", getBaseTime())
                .addQueryParameter("nx", String.valueOf(nx))
                .addQueryParameter("ny", String.valueOf(ny))
                .addQueryParameter("numOfRows", "100")
                .build();

        Log.d(TAG, "요청 URL: " + url.toString());

        Request req = new Request.Builder().url(url).build();
        Response resp = new OkHttpClient().newCall(req).execute();

        if (!resp.isSuccessful()) {
            throw new IOException("Unexpected code " + resp);
        }
        return resp.body().string();
    }

    private String getBaseDate() {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd");
        return sdf.format(new Date());
    }

    private String getBaseTime() {
        Calendar cal = Calendar.getInstance();
        cal.add(Calendar.HOUR_OF_DAY, -1); // 현재 시간에서 1시간 전으로 이동
        int hour = cal.get(Calendar.HOUR_OF_DAY);
        return String.format("%02d00", hour); // 정시 형식으로 반환
    }
}
