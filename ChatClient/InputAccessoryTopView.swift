//
//  InputAccessoryTopView.swift
//  ChatClient
//
//  Created by Parvinder on 08/06/19.
//  Copyright © 2019 Sourcefuse. All rights reserved.
//

import MessageKit
import InputBarAccessoryView
import MaterialComponents

class mInputItem : UIView, InputItem, UICollectionViewDataSource, UICollectionViewDelegate {
    
    private lazy var layout = MDCChipCollectionViewFlowLayout.init()
    private lazy var collectionView = UICollectionView.init(frame: .zero, collectionViewLayout: layout)
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        collectionView.register(MDCChipCollectionViewCell.self, forCellWithReuseIdentifier: "chip")
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        self.addSubview(collectionView)
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = CGSize.init(width: 10.0, height: 1.0)
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.collectionView.frame = self.bounds
    }
    
    var inputBarAccessoryView: InputBarAccessoryView?
    
    var parentStackViewPosition: InputStackView.Position?
    
    func textViewDidChangeAction(with textView: InputTextView) {}
    
    func keyboardSwipeGestureAction(with gesture: UISwipeGestureRecognizer) {}
    
    func keyboardEditingEndsAction() {}
    
    func keyboardEditingBeginsAction() {}
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 200, height: 44)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        inputBarAccessoryView?.inputTextView.text = "Hello"
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Configuration.shared.hints.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "chip", for: indexPath) as! MDCChipCollectionViewCell
        
        let chipView = cell.chipView
        
        // Configure
        
        chipView.titleLabel.text = Configuration.shared.hints[indexPath.row]
        
        chipView.sizeToFit()
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var text = self.inputBarAccessoryView?.inputTextView.text.trimmingCharacters(in: CharacterSet.whitespaces) ?? ""
        text += " " + Configuration.shared.hints[indexPath.row] + " "
        self.inputBarAccessoryView?.inputTextView.text = text
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
