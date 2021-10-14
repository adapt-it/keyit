package com.ccs.kitand

import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.ImageView
import androidx.recyclerview.widget.RecyclerView

//	The PopupAdapter populates the popover menu RecyclerView.
//
//  Created by Graeme Costin on 9MAR21?.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

class PopupAdapter(
	var curPoMenu: VIMenu,
	var edChAct: EditChapterActivity
)
	: RecyclerView.Adapter<PopupAdapter.PopupCell>(){

	// Create new view holders (invoked by the layout manager)
	override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): PopupAdapter.PopupCell {
		// create a new view
		val itemView = LayoutInflater.from(parent.context)
			.inflate(R.layout.popup_item, parent, false)
		// set the view's size, margins, paddings and layout parameters

		return PopupCell(itemView)
	}

	override fun onBindViewHolder(holder: PopupCell, position: Int) {
		// - get element from your dataset at this position
		// - replace the contents of the view with that element's data
		val menuText = curPoMenu.VIMenuItems[position].VIMenuLabel
		holder.menu_cmd.setText(menuText)
		holder.menu_cmd.setFocusable(false)
		when (curPoMenu.VIMenuItems[position].VIMenuIcon) {
			"C" -> holder.popup_icon.setImageResource(R.drawable.create_pubitem)
			"D" -> holder.popup_icon.setImageResource(R.drawable.delete_pubitem)
			"B" -> holder.popup_icon.setImageResource(R.drawable.bridge_pubitem)
			"U" -> holder.popup_icon.setImageResource(R.drawable.unbridge_pubitem)
		}

		// Listeners for PopMenuItem selected
		holder.popup_icon.setOnClickListener(View.OnClickListener {
			// A PopupCell icon has been tapped
			val menuPos = holder.getAdapterPosition()
			edChAct.popMenuAction(menuPos)
		})
		holder.menu_cmd.setOnClickListener(View.OnClickListener {
			// A PopupCell menu command has been tapped
			val menuPos = holder.getAdapterPosition()
			edChAct.popMenuAction(menuPos)
		})
	}

	override fun getItemCount(): Int {
		val numItems = curPoMenu.VIMenuItems.size
		return numItems
	}

	// PopupCell class provides a reference to each widget in a view holder
	inner class PopupCell(itemView: View) : RecyclerView.ViewHolder(itemView) {
		var popup_icon: ImageView = itemView.findViewById(R.id.popup_icon)
		var menu_cmd: EditText = itemView.findViewById(R.id.menu_cmd)
	}
}