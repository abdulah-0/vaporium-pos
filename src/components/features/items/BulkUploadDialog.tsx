'use client'

import { useState, useRef } from 'react'
import { createClient } from '@/lib/supabase/client'
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogDescription,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { useToast } from '@/components/ui/toast'
import { Upload, Download, CheckCircle2, XCircle, Loader2, FileSpreadsheet } from 'lucide-react'

interface BulkUploadDialogProps {
    open: boolean
    onOpenChange: (open: boolean) => void
    tenantId: string
    onUploaded: () => void
}

interface ParsedRow {
    name: string
    category: string
    item_number: string
    description: string
    cost_price: number
    unit_price: number
    reorder_level: number
    error?: string
}

const CSV_TEMPLATE_HEADERS = [
    'name',
    'category',
    'item_number',
    'description',
    'cost_price',
    'unit_price',
    'reorder_level',
]

const SAMPLE_ROWS = [
    ['Wireless Mouse', 'Electronics', 'ELEC-001', 'Ergonomic wireless mouse', '12.50', '24.99', '5'],
    ['Coffee Mug 12oz', 'Kitchen', 'KITCH-002', 'Ceramic coffee mug', '3.00', '8.99', '10'],
]

function downloadTemplate() {
    const rows = [CSV_TEMPLATE_HEADERS, ...SAMPLE_ROWS]
    const csv = rows.map((r) => r.map((v) => `"${v}"`).join(',')).join('\n')
    const blob = new Blob([csv], { type: 'text/csv' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'items_bulk_upload_template.csv'
    a.click()
    URL.revokeObjectURL(url)
}

function parseCSV(text: string): ParsedRow[] {
    const lines = text.trim().split(/\r?\n/)
    if (lines.length < 2) return []

    // Strip header row
    const dataLines = lines.slice(1)

    return dataLines.map((line, idx) => {
        // Handle quoted CSV values
        const values: string[] = []
        let current = ''
        let inQuotes = false
        for (const char of line) {
            if (char === '"') {
                inQuotes = !inQuotes
            } else if (char === ',' && !inQuotes) {
                values.push(current.trim())
                current = ''
            } else {
                current += char
            }
        }
        values.push(current.trim())

        const [name, category, item_number, description, cost_price_str, unit_price_str, reorder_level_str] = values

        if (!name) {
            return { name: '', category: '', item_number: '', description: '', cost_price: 0, unit_price: 0, reorder_level: 0, error: `Row ${idx + 2}: Name is required` }
        }

        const cost_price = parseFloat(cost_price_str) || 0
        const unit_price = parseFloat(unit_price_str) || 0
        const reorder_level = parseInt(reorder_level_str) || 0

        if (unit_price <= 0) {
            return { name, category, item_number, description, cost_price, unit_price, reorder_level, error: `Row ${idx + 2}: Unit price must be greater than 0` }
        }

        return { name, category: category || '', item_number: item_number || '', description: description || '', cost_price, unit_price, reorder_level }
    })
}

export default function BulkUploadDialog({ open, onOpenChange, tenantId, onUploaded }: BulkUploadDialogProps) {
    const fileRef = useRef<HTMLInputElement>(null)
    const { showToast } = useToast()

    const [parsedRows, setParsedRows] = useState<ParsedRow[]>([])
    const [fileName, setFileName] = useState('')
    const [uploading, setUploading] = useState(false)
    const [uploadResult, setUploadResult] = useState<{ success: number; failed: number } | null>(null)

    const validRows = parsedRows.filter((r) => !r.error)
    const errorRows = parsedRows.filter((r) => r.error)

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0]
        if (!file) return
        setFileName(file.name)
        setUploadResult(null)

        const reader = new FileReader()
        reader.onload = (ev) => {
            const text = ev.target?.result as string
            const rows = parseCSV(text)
            setParsedRows(rows)
        }
        reader.readAsText(file)
    }

    const handleUpload = async () => {
        if (validRows.length === 0) return
        setUploading(true)

        try {
            const supabase = createClient()
            const inserts = validRows.map((row) => ({
                tenant_id: tenantId,
                name: row.name,
                category: row.category,
                item_number: row.item_number,
                description: row.description,
                cost_price: row.cost_price,
                unit_price: row.unit_price,
                reorder_level: row.reorder_level,
                receiving_quantity: 1,
                allow_alt_description: false,
                is_serialized: false,
                deleted: false,
            }))

            const { error } = await supabase.from('items').insert(inserts)

            if (error) throw error

            setUploadResult({ success: validRows.length, failed: errorRows.length })
            showToast('success', `${validRows.length} item(s) uploaded successfully!`)
            onUploaded()
        } catch (err) {
            console.error(err)
            showToast('error', 'Upload failed. Please check your file and try again.')
        } finally {
            setUploading(false)
        }
    }

    const handleClose = (val: boolean) => {
        if (!val) {
            setParsedRows([])
            setFileName('')
            setUploadResult(null)
            if (fileRef.current) fileRef.current.value = ''
        }
        onOpenChange(val)
    }

    return (
        <Dialog open={open} onOpenChange={handleClose}>
            <DialogContent className="sm:max-w-2xl">
                <DialogHeader>
                    <DialogTitle className="flex items-center gap-2">
                        <Upload className="h-5 w-5 text-purple-500" />
                        Bulk Upload Items
                    </DialogTitle>
                    <DialogDescription>
                        Upload a CSV file to add multiple items at once. Download the template to get started.
                    </DialogDescription>
                </DialogHeader>

                <div className="space-y-4">
                    {/* Step 1: Download template */}
                    <div className="flex items-center gap-3 p-3 rounded-lg bg-purple-50 border border-purple-100">
                        <FileSpreadsheet className="h-8 w-8 text-purple-400 shrink-0" />
                        <div className="flex-1">
                            <p className="text-sm font-medium text-gray-700">Step 1: Download the template</p>
                            <p className="text-xs text-gray-400">Fill in your items, then upload the file below</p>
                        </div>
                        <Button variant="outline" size="sm" onClick={downloadTemplate} className="shrink-0 text-purple-700 border-purple-200 hover:bg-purple-100">
                            <Download className="h-4 w-4 mr-1.5" />
                            Template
                        </Button>
                    </div>

                    {/* Step 2: Upload */}
                    <div>
                        <p className="text-sm font-medium text-gray-700 mb-2">Step 2: Upload your CSV file</p>
                        <label
                            htmlFor="csv-upload"
                            className="flex flex-col items-center justify-center w-full h-28 border-2 border-dashed border-gray-200 rounded-xl cursor-pointer hover:border-purple-400 hover:bg-purple-50 transition-colors"
                        >
                            <Upload className="h-7 w-7 text-gray-300 mb-1" />
                            <span className="text-sm text-gray-500">
                                {fileName ? fileName : 'Click to browse or drag & drop'}
                            </span>
                            <span className="text-xs text-gray-400">.csv files only</span>
                            <input
                                id="csv-upload"
                                ref={fileRef}
                                type="file"
                                accept=".csv"
                                className="hidden"
                                onChange={handleFileChange}
                            />
                        </label>
                    </div>

                    {/* Preview */}
                    {parsedRows.length > 0 && !uploadResult && (
                        <div className="rounded-lg border border-gray-100 overflow-hidden">
                            <div className="flex items-center justify-between px-4 py-2 bg-gray-50 border-b border-gray-100">
                                <span className="text-sm font-medium text-gray-700">Preview — {parsedRows.length} row(s) detected</span>
                                <div className="flex items-center gap-3 text-xs">
                                    <span className="text-green-600 font-medium flex items-center gap-1">
                                        <CheckCircle2 className="h-3.5 w-3.5" /> {validRows.length} valid
                                    </span>
                                    {errorRows.length > 0 && (
                                        <span className="text-red-500 font-medium flex items-center gap-1">
                                            <XCircle className="h-3.5 w-3.5" /> {errorRows.length} errors
                                        </span>
                                    )}
                                </div>
                            </div>
                            <div className="max-h-48 overflow-y-auto">
                                <table className="w-full text-xs">
                                    <thead className="bg-gray-50 sticky top-0">
                                        <tr>
                                            {['Name', 'Category', 'Item #', 'Cost', 'Price', 'Status'].map((h) => (
                                                <th key={h} className="text-left px-3 py-1.5 text-gray-500 font-medium">{h}</th>
                                            ))}
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {parsedRows.map((row, i) => (
                                            <tr key={i} className={`border-t border-gray-50 ${row.error ? 'bg-red-50' : ''}`}>
                                                <td className="px-3 py-1.5 font-medium text-gray-800">{row.name || '—'}</td>
                                                <td className="px-3 py-1.5 text-gray-500">{row.category || '—'}</td>
                                                <td className="px-3 py-1.5 text-gray-500 font-mono">{row.item_number || '—'}</td>
                                                <td className="px-3 py-1.5 text-gray-500">{row.cost_price.toFixed(2)}</td>
                                                <td className="px-3 py-1.5 text-gray-700 font-medium">{row.unit_price.toFixed(2)}</td>
                                                <td className="px-3 py-1.5">
                                                    {row.error
                                                        ? <span className="text-red-500 flex items-center gap-1"><XCircle className="h-3 w-3" />{row.error}</span>
                                                        : <span className="text-green-600 flex items-center gap-1"><CheckCircle2 className="h-3 w-3" />OK</span>
                                                    }
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    )}

                    {/* Upload result */}
                    {uploadResult && (
                        <div className="rounded-lg bg-green-50 border border-green-100 p-4 flex items-center gap-3">
                            <CheckCircle2 className="h-6 w-6 text-green-500 shrink-0" />
                            <div>
                                <p className="font-medium text-green-800">Upload complete!</p>
                                <p className="text-sm text-green-600">
                                    {uploadResult.success} item(s) added successfully
                                    {uploadResult.failed > 0 && `, ${uploadResult.failed} skipped due to errors`}
                                </p>
                            </div>
                        </div>
                    )}

                    {/* Action buttons */}
                    <div className="flex justify-end gap-2 pt-2">
                        <Button variant="outline" onClick={() => handleClose(false)} disabled={uploading}>
                            {uploadResult ? 'Close' : 'Cancel'}
                        </Button>
                        {!uploadResult && validRows.length > 0 && (
                            <Button
                                onClick={handleUpload}
                                disabled={uploading}
                                className="text-white font-semibold"
                                style={{ background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' }}
                            >
                                {uploading ? (
                                    <><Loader2 className="h-4 w-4 mr-2 animate-spin" />Uploading...</>
                                ) : (
                                    <><Upload className="h-4 w-4 mr-2" />Upload {validRows.length} Item{validRows.length > 1 ? 's' : ''}</>
                                )}
                            </Button>
                        )}
                    </div>
                </div>
            </DialogContent>
        </Dialog>
    )
}
