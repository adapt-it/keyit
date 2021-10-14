package com.ccs.kitand

import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView

class ChapterAdapter (
	var BibChaps: ArrayList<Book.BibChap>,
	var chChAct: ChooseChapterActivity
) : RecyclerView.Adapter<ChapterAdapter.ChapterCell>() {

	// Create new view holders (invoked by the layout manager)
	override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ChapterAdapter.ChapterCell {
		// create a new view
		val itemView = LayoutInflater.from(parent.context)
			.inflate(R.layout.chapter_item, parent, false)
		// set the view's size, margins, paddings and layout parameters

		return ChapterCell(itemView)
	}

	override fun onBindViewHolder(holder: ChapterAdapter.ChapterCell, position: Int) {
		// - get element from your dataset at this position
		// - replace the contents of the view with that element's data
		val bibChap = BibChaps[position]
		val chapNum = bibChap.chNum
		val chapNumText = chChAct.chOrPsName + " " + chapNum.toString()
		holder.chapNum.setText(chapNumText)
		var numVsItText = ""
		val curVsNum = bibChap.curVN
		if (bibChap.itRCr) {
			// Set colour of chapter number text
			holder.chapNum.setTextColor(Color.parseColor("#0000CD"))
			if (curVsNum > 0) {
				numVsItText = "Vs " + curVsNum.toString() + " "
			}
			numVsItText += "(" + bibChap.numVs.toString() + " vs)"
			// Set colour of text
			holder.chapInfo.setTextColor(Color.parseColor("#0000CD"))
		}
		holder.chapInfo.setText(numVsItText)

		// Listeners for Chapter selected
		holder.chapNum.setOnClickListener(View.OnClickListener {
			// A BookCell icon has been tapped
			val chapOfst = holder.getAdapterPosition()
			chChAct.chooseChapterAction(chapOfst)
		})
		holder.chapInfo.setOnClickListener(View.OnClickListener {
			// A PopupCell menu command has been tapped
			val chapOfst = holder.getAdapterPosition()
			chChAct.chooseChapterAction(chapOfst)
		})
	}

	override fun getItemCount(): Int {
		val numItems = BibChaps.size
		return numItems
	}

	inner class ChapterCell(itemView: View) : RecyclerView.ViewHolder(itemView) {
		var chapNum: TextView = itemView.findViewById(R.id.chapNum)
		var chapInfo: TextView = itemView.findViewById(R.id.chapInfo)
	}
}