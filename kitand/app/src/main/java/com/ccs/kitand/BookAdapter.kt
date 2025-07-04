package com.ccs.kitand

import android.text.Editable
import android.text.InputType
import android.text.TextWatcher
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import androidx.core.graphics.toColorInt

class BookAdapter (
	var BibBooks: ArrayList<Bible.BibBook>,
	var chBkAct: ChooseBookActivity
) : RecyclerView.Adapter<BookAdapter.BookCell>(){

	// Create new view holders (invoked by the layout manager)
	override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): BookAdapter.BookCell {
		// create a new view
		val itemView = LayoutInflater.from(parent.context)
			.inflate(R.layout.book_item, parent, false)
		// set the view's size, margins, paddings and layout parameters

		return BookCell(itemView)
	}

	override fun onBindViewHolder(holder: BookCell, position: Int) {
		// - get element from your dataset at this position
		// - replace the contents of the view with that element's data
		val book = BibBooks[position]
		val bookName = book.bkName
		holder.bookName.setText(bookName)
		//GDLC 18JUN25 Added InputType to avoid spell correct suggestions
		holder.bookName.setInputType(InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS)

		val numCh = book.numCh
		val curChapID = BibBooks[position].curChID
		val curChNum = BibBooks[position].curChNum
		var bookInfo = ""
		if (book.chapRCr) {
			// Set colour of text
			holder.bookName.setTextColor("#0000CD".toColorInt())
			// GDLC 29MAY25 use Ps if Psalms
			if (curChapID > 0) {
					bookInfo = (if (book.bkID == 19) "Ps " else "Ch") + curChNum.toString() + " "
			}
				//GDLC 18JUN25 Added closing parenthesis after "ch"
				bookInfo += "(" + numCh.toString() + (if (book.bkID == 19) " ps)" else " ch)")
		}
		// Set info text
		bookInfo = bookInfo + " >"
		holder.bookInfo.setText(bookInfo)
		holder.bookInfo.setTextColor("#0000CD".toColorInt())

/*		// Listeners for Book selected or Book name edit
		holder.bookName.setOnClickListener(View.OnClickListener {
			// A BookCell bookName has been tapped
			val bookOfst = holder.getBindingAdapterPosition()
//			chBkAct.chooseBookAction(bookOfst)
		})*/
		holder.bookName.addTextChangedListener(object : TextWatcher {
			override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {
//				TODO("Not yet implemented")
			}
			override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
//				TODO("Not yet implemented")
			}
			override fun afterTextChanged(s: Editable) {
				// Set dirty flag for this bookName
				holder.dirty = true
				val bookOfst = holder.getBindingAdapterPosition()
				BibBooks[bookOfst].dirty = true
				BibBooks[bookOfst].bkName = s.toString()
			}
		})
		holder.bookInfo.setOnClickListener(View.OnClickListener {
			// A BookCell bookInfo has been tapped
			val bookOfst = holder.getBindingAdapterPosition()
			chBkAct.chooseBookAction(bookOfst)
		})
	}

	override fun getItemCount(): Int {
		val numItems = BibBooks.size
		return numItems
	}

	inner class BookCell(itemView: View) : RecyclerView.ViewHolder(itemView) {
		var bookName: TextView = itemView.findViewById(R.id.bookName)
		var bookInfo: TextView = itemView.findViewById(R.id.bookInfo)
		var dirty: Boolean = false /* initialised to false, set true when bookName is edited */
	}
}