import 'dart:convert';

import 'package:extruck/db/db_helper.dart';
import 'package:extruck/order/rmt_history/connect_printer.dart';
import 'package:extruck/order/rmt_history/reprint_report.dart';
import 'package:extruck/values/userdata.dart';
import 'package:extruck/widgets/dialogs.dart';
// import 'package:extruck/values/userdata.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';

class ReportsHistoryLine extends StatefulWidget {
  final String rmtNo, ordNo, totAmt;

  // ignore: use_key_in_widget_constructors
  const ReportsHistoryLine(this.rmtNo, this.ordNo, this.totAmt);

  // const ReportsHistoryLine({Key? key}) : super(key: key);

  @override
  State<ReportsHistoryLine> createState() => _ReportsHistoryLineState();
}

class _ReportsHistoryLineState extends State<ReportsHistoryLine> {
  List _list = [];
  double ordAmt = 0.00;
  double boAmt = 0.00;
  final db = DatabaseHelper();

  final formatCurrencyAmt = NumberFormat.currency(locale: "en_US", symbol: "₱");

  @override
  void initState() {
    super.initState();
    loadRemittanceHistoryLine();
  }

  loadRemittanceHistoryLine() async {
    var rsp = await db.loadRmtHistoryLine(widget.rmtNo);
    setState(() {
      _list = json.decode(json.encode(rsp));
      for (var element in _list) {
        if (element['tran_type'] == 'BO') {
          boAmt = boAmt + double.parse(element['tot_amt'].toString());
        }
        if (element['tran_type'] == 'ORDER') {
          ordAmt = ordAmt + double.parse(element['tot_amt'].toString());
        }
        String newDate = "";
        DateTime s = DateTime.parse(element['date']);
        newDate =
            '${DateFormat("MMM dd, yyyy").format(s)} at ${DateFormat("hh:mm aaa").format(s)}';
        element['date'] = newDate.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '#${widget.rmtNo}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                String msg = 'Are you sure you want to reprint report?';
                // ignore: use_build_context_synchronously
                final action = await WarningDialogs.openDialog(
                  context,
                  'Information',
                  msg,
                  true,
                  'OK',
                );
                if (action == DialogAction.yes) {
                  if (!PrinterData.connected) {
                    // ignore: use_build_context_synchronously
                    Navigator.push(
                        context,
                        PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: ConnectPrinter(
                                _list,
                                widget.rmtNo,
                                ordAmt.toString(),
                                boAmt.toString(),
                                widget.ordNo,
                                widget.totAmt)));
                  } else {
                    // ignore: use_build_context_synchronously
                    Navigator.push(
                        context,
                        PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: ReprintReport(
                                _list,
                                widget.rmtNo,
                                ordAmt.toString(),
                                boAmt.toString(),
                                widget.ordNo,
                                widget.totAmt)));
                  }
                } else {}
              },
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
              ),
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: buildListView(context),
          ),
          buildTotalCont(context),
        ],
      ),
    );
  }

  Container buildTotalCont(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(width: 0.1, color: Colors.grey),
        ),
      ),
      width: MediaQuery.of(context).size.width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        // ignore: prefer_const_literals_to_create_immutables
        children: [
          const Text('Total Orders: ', style: TextStyle(fontSize: 12)),
          Expanded(
              child: Text(widget.ordNo,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.deepOrange))),
          const Text('Total Amount: ', style: TextStyle(fontSize: 12)),
          Text(formatCurrencyAmt.format(double.parse(widget.totAmt)),
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.deepOrange)),
        ],
      ),
    );
  }

  Container buildListView(BuildContext context) {
    if (_list.isEmpty) {
      return Container(
        color: Colors.grey[100],
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.error_outline_outlined,
              size: 100,
              color: Colors.orange[500],
            ),
            Text(
              'No orders found.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            )
          ],
        ),
      );
    }
    return Container(
      width: MediaQuery.of(context).size.width,
      color: Colors.transparent,
      child: ListView.builder(
          itemCount: _list.length,
          itemBuilder: ((context, index) {
            bool boRef = false;
            bool cash = false;
            // String newDate = "";
            // String date = "";
            // date = _list[index]['date'].toString();
            // DateTime s = DateTime.parse(date);
            // newDate =
            //     '${DateFormat("MMM dd, yyyy").format(s)} at ${DateFormat("hh:mm aaa").format(s)}';
            // _list[index]['date'] = newDate.toString();
            if (_list[index]['pmeth_type'] == 'Cash') {
              cash = true;
            } else {
              cash = false;
            }

            if (_list[index]['tran_type'] == 'BO') {
              boRef = true;
            } else {
              boRef = false;
            }

            return Container(
              // width: MediaQuery.of(context).size.width,
              color: Colors.white,
              // height: 70,
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              child: Row(
                // ignore: prefer_const_literals_to_create_immutables
                children: [
                  Icon(
                    cash ? Icons.money_rounded : Icons.fact_check_outlined,
                    color: cash ? Colors.green : Colors.deepOrange,
                    size: 36,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _list[index]['order_no'],
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _list[index]['store_name'],
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SI #: ',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w400),
                            ),
                            Text(
                              _list[index]['si_no'],
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green),
                            ),
                          ],
                        ),
                        Text(
                          _list[index]['date'],
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    // ignore: prefer_const_literals_to_create_immutables
                    children: [
                      Visibility(
                        visible: boRef,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          color: Colors.grey,
                          child: const Text(
                            'BO REFUND',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w400),
                      ),
                      Text(
                        formatCurrencyAmt
                            .format(double.parse(_list[index]['tot_amt'])),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green),
                      ),
                    ],
                  )
                ],
              ),
            );
          })),
    );
  }
}
