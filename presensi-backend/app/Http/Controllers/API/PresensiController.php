<?php

namespace App\Http\Controllers\API;

use DB;
use stdClass;
use Carbon\Carbon;
use App\Models\Presensi;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Auth;

date_default_timezone_set("Asia/Jakarta");

class PresensiController extends Controller
{
    function getPresensis()
    {
        $presensis = Presensi::where('user_id', Auth::user()->id)->get();
        foreach ($presensis as $item) {
            $item->is_hari_ini = ($item->tanggal == date('Y-m-d'));
    
            $datetime = Carbon::parse($item->tanggal)->locale('id');
            $masuk = Carbon::parse($item->masuk)->locale('id');
            $pulang = $item->pulang ? Carbon::parse($item->pulang)->locale('id') : null;
    
            $datetime->settings(['formatFunction' => 'translatedFormat']);
            $masuk->settings(['formatFunction' => 'translatedFormat']);
            if ($pulang) {
                $pulang->settings(['formatFunction' => 'translatedFormat']);
            }
    
            $item->tanggal = $datetime->format('l, j F Y');
            $item->masuk = $masuk->format('H:i');
            $item->pulang = $pulang ? $pulang->format('H:i') : '-';
        }
    
        return response()->json([
            'success' => true,
            'message' => 'Sukses menampilkan data',
            'data' => $presensis
        ]);
    }
    
    function savePresensi(Request $request)
    {
        $userId = Auth::user()->id;
        $keterangan = "";
        
        // Cari presensi berdasarkan user_id dan tanggal hari ini
        $presensi = Presensi::whereDate('tanggal', date('Y-m-d'))
            ->where('user_id', $userId)
            ->first();
    
        if ($presensi == null) {
            // Buat presensi baru untuk masuk
            $presensi = Presensi::create([
                'user_id' => $userId,
                'latitude' => $request->latitude,
                'longitude' => $request->longitude,
                'tanggal' => date('Y-m-d'),
                'masuk' => date('H:i:s'),
                'pulang' => null
            ]);
            return response()->json([
                'success' => true,
                'message' => 'Sukses absen untuk masuk',
                'data' => $presensi
            ]);
        } else {
            if ($presensi->pulang !== null) {
                $keterangan = "Anda sudah melakukan presensi";
                return response()->json([
                    'success' => false,
                    'message' => $keterangan,
                    'data' => null
                ]);
            } else {
                // Update hanya untuk user yang sedang login
                $presensi->update([
                    'pulang' => date('H:i:s')
                ]);
            }
    
            return response()->json([
                'success' => true,
                'message' => 'Sukses Absen untuk Pulang',
                'data' => $presensi
            ]);
        }
    }
    
}
