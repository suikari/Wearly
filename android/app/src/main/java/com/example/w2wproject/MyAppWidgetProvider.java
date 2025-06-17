package com.example.w2wproject;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.Intent;
import android.util.Log;
import android.widget.RemoteViews;

import androidx.work.OneTimeWorkRequest;
import androidx.work.WorkManager;

public class MyAppWidgetProvider extends AppWidgetProvider {
    public static final String ACTION_REFRESH = "com.example.w2wproject.ACTION_REFRESH";
    private static final String TAG = "MyAppWidgetProvider";

    @Override
    public void onUpdate(Context ctx, AppWidgetManager mgr, int[] ids) {
        super.onUpdate(ctx, mgr, ids);
        Log.d(TAG, "onUpdate 호출, 위젯 ID 수: " + ids.length);
        for (int id : ids) {
            updateAppWidget(ctx, mgr, id, "로딩 중...", "--°C");
        }
        startUpdateWork(ctx);
    }

    @Override
    public void onReceive(Context ctx, Intent it) {
        super.onReceive(ctx, it);
        if (ACTION_REFRESH.equals(it.getAction())) {
            Log.d(TAG, "새로고침 버튼 클릭 - WorkManager 실행");
            startUpdateWork(ctx);
        }
    }

    // 기존 startUpdateService() 대신 WorkManager 호출 함수
    private void startUpdateWork(Context ctx) {
        OneTimeWorkRequest workRequest = new OneTimeWorkRequest.Builder(UpdateWidgetWorker.class).build();
        WorkManager.getInstance(ctx).enqueue(workRequest);
    }

    public static void updateAppWidget(Context ctx, AppWidgetManager mgr, int appId,
                                       String weather, String temp) {
        RemoteViews views = new RemoteViews(ctx.getPackageName(), R.layout.widget_layout);


//        Intent intent = new Intent(ctx, MainActivity.class);
//        PendingIntent pendingIntent = PendingIntent.getActivity(
//                ctx, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
//        );
//
//        views.setOnClickPendingIntent(R.id.widget_root_layout, pendingIntent);

        views.setTextViewText(R.id.weatherText, "ㅅ날씨: " + weather);
        views.setTextViewText(R.id.tempText, temp);

        Intent refreshIntent = new Intent(ctx, MyAppWidgetProvider.class);
        refreshIntent.setAction(ACTION_REFRESH);
        PendingIntent refreshPendingIntent = PendingIntent.getBroadcast(ctx, 0, refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        views.setOnClickPendingIntent(R.id.refreshButton, refreshPendingIntent);

        mgr.updateAppWidget(appId, views);
        Log.d(TAG, "위젯 업데이트 완료 - 날씨: " + weather + ", 온도: " + temp);
    }
}
