---
date: 2007-07-16 21:22:37+00:00
slug: mysql-bigint-types-and-ibatis
title: MySQL bigint types and iBATIS
categories:
  - Java
---

One nuance I recently ran into while using [iBATIS](http://ibatis.apache.org/)
was inserting data into [MySQL](http://www.mysql.com/) bigint unsigned columns.
iBATIS doesn't seem to have a way to handle BigInteger data types and throws an
exception when attempting to do an insert. Fetching data out seemed to work OK
because if iBATIS doesn't know how to handle a certain type it just returns a
java.lang.Object. The way to go about inserting BigInteger types is to set up a
type handler. Here's an example type handler for BigInteger types:<!--more-->

{{< highlight java >}}
package org.qnot.util;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.sql.SQLException;
import java.sql.Types;

import com.ibatis.sqlmap.client.extensions.ParameterSetter;
import com.ibatis.sqlmap.client.extensions.ResultGetter;
import com.ibatis.sqlmap.client.extensions.TypeHandlerCallback;

public class BigIntegerTypeHandler implements TypeHandlerCallback {

    public Object getResult(ResultGetter getter) throws SQLException {
        if(getter.wasNull()) {
            return null;
        }

        Object o = getter.getObject();
        if(o instanceof BigDecimal) {
            BigDecimal bd = (BigDecimal)o;
            return bd.toBigInteger();
        } else if(o instanceof BigInteger) {
            return (BigInteger)o;
        } else {
            return o;
        }
    }

    public void setParameter(ParameterSetter setter, Object parameter)
            throws SQLException {
        if (parameter == null) {
            setter.setNull(Types.BIGINT);
        } else {
            BigInteger i = (BigInteger) parameter;
            setter.setBigDecimal(new BigDecimal(i));
        }
    }

    public Object valueOf(String s) {
        return s;
    }
}
{{< /highlight >}}
