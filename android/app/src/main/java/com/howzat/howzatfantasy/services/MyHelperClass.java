package com.howzat.howzatfantasy.services;

import android.net.Uri;

public class MyHelperClass {

    public String getQueryParmValueFromUrl(String url, String attribute) {
        Uri uri = Uri.parse(url);
        String value = uri.getQueryParameter(attribute);
        return value;
    }

}
