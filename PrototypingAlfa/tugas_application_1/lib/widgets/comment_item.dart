import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🔥 JANGAN LUPA IMPORT INI
import 'verification_badge.dart';

class CommentItem extends StatefulWidget {
  final Map comment;
  final int currentUserId;
  final Function(int commentId) onDelete;

  const CommentItem({super.key, required this.comment, required this.currentUserId, required this.onDelete});

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  bool _isExpanded = false;

  void _showOptions() {
    int ownerId = widget.comment['user_id'];
    bool isMine = ownerId == widget.currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100.w,
                height: 10.h,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10.r)),
              ),
              SizedBox(height: 50.h),

              if (isMine)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red, size: 50.sp),
                  title: Text(
                    "Delete Comment",
                    style: TextStyle(fontSize: 35.sp, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onDelete(widget.comment['id']);
                  },
                )
              else
                ListTile(
                  leading: Icon(Icons.flag_outlined, color: Colors.red, size: 50.sp),
                  title: Text(
                    "Report Comment",
                    style: TextStyle(fontSize: 35.sp, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thanks for reporting.")));
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. DATA USER (FLAT)
    // Kita baca langsung dari root karena backend sudah kita set FLAT
    String displayName = widget.comment['display_name'] ?? widget.comment['username'] ?? "User";
    String profilePicUrl = widget.comment['profile_pic_url'] ?? "";
    String tier = widget.comment['tier'] ?? 'regular';

    final double commentFontSize = 35.sp;
    final double actionFontSize = 30.sp;
    final double heartIconTopPadding = 60.h;

    final TextStyle textStyle = TextStyle(color: Colors.black, fontSize: commentFontSize, height: 1.3);

    return GestureDetector(
      onLongPress: _showOptions,
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.only(bottom: 40.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. AVATAR (VERSI KUAT - CACHED NETWORK IMAGE)
            // Ini logika yang sama persis dengan PostItem
            CircleAvatar(
              radius: 50.r,
              backgroundColor: Colors.grey.shade200,
              child: (profilePicUrl.isNotEmpty)
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: profilePicUrl,
                        fit: BoxFit.cover,
                        width: 100.r,
                        height: 100.r,
                        // Kalau loading, kasih warna abu
                        placeholder: (context, url) => Container(color: Colors.grey.shade200),
                        // Kalau error/gagal load, kasih Icon Orang
                        errorWidget: (context, url, error) => Icon(Icons.person, color: Colors.grey, size: 50.sp),
                      ),
                    )
                  : Icon(Icons.person, color: Colors.grey, size: 50.sp),
            ),

            SizedBox(width: 30.w),

            // 3. KONTEN KOMENTAR
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username / Display Name
                  Row(
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30.sp),
                      ),
                      SizedBox(width: 4.w),
                      VerificationBadge(tier: tier, size: 30.sp),
                    ],
                  ),
                  SizedBox(height: 0.h),

                  // Isi Komen
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final String text = widget.comment['comment_text'] ?? "";
                      final span = TextSpan(text: text, style: textStyle);
                      final tp = TextPainter(text: span, maxLines: 2, textDirection: TextDirection.ltr);
                      tp.layout(maxWidth: constraints.maxWidth);

                      final bool hasOverflow = tp.didExceedMaxLines;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            style: textStyle,
                            maxLines: _isExpanded ? null : 2,
                            overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 15.h),
                          Row(
                            children: [
                              Text(
                                "Reply",
                                style: TextStyle(
                                  fontSize: actionFontSize,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (hasOverflow) ...[
                                SizedBox(width: 30.w),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _isExpanded = !_isExpanded);
                                  },
                                  child: Text(
                                    _isExpanded ? "Less" : "More",
                                    style: TextStyle(
                                      fontSize: actionFontSize,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // 4. ICON LOVE
            SizedBox(width: 20.w),
            Padding(
              padding: EdgeInsets.only(top: heartIconTopPadding),
              child: Icon(Icons.favorite_border, size: 40.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
